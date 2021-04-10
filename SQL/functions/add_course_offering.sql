/*
    10. add_course_offering: This routine is used to add a new offering of an existing course.
    The inputs to the routine include the following:
        course offering identifier,
        course identifier,
        course fees,
        launch date,
        registration deadline,
        target number of registrations,
        administrator's identifier,and
        information for each session (session date, session start hour, and room identifier).
    If the input course offering information is valid, the routine will assign instructors for the sessions.
    If a valid instructor assignment exists, the routine will perform the necessary updates to add the course offering;
        otherwise, the routine will abort the course offering addition.
    Note that the seating capacity of the course offering must be at least equal to the course offering's target number of registrations.
*/

DROP TYPE IF EXISTS session_information;
CREATE TYPE session_information AS (
    session_date DATE,
    session_start_hour INTEGER,
    room_id INTEGER
);

DROP FUNCTION IF EXISTS add_course_offering CASCADE;
CREATE OR REPLACE FUNCTION add_course_offering (
    offering_launch_date_arg DATE,
    offering_fees_arg DEC(64, 2),
    sessions_arr session_information ARRAY,
    offering_registration_deadline_arg DATE,
    offering_num_target_registration_arg INTEGER,
    course_id_arg INTEGER,
    admin_id_arg INTEGER
)
RETURNS TABLE(
    offering_launch_date DATE,
    offering_fees DEC(64,2),
    offering_registration_deadline DATE,
    offering_num_target_registration INTEGER,
    offering_seating_capacity INTEGER,
    course_id INTEGER,
    admin_id INTEGER,
    offering_start_date DATE,
    offering_end_date DATE
) AS $$
DECLARE
    off_start_date DATE;
    off_end_date DATE;
    session_end_hour INTEGER;
    num_sessions INTEGER;
    course_duration INTEGER;
    instructor_id INTEGER;
    final_offering_seating_capacity INTEGER;
    new_course_offering RECORD;
BEGIN
    /* Check for NULLs in arguments */
    IF offering_launch_date_arg IS NULL
        OR offering_fees_arg IS NULL
        OR sessions_arr IS NULL
        OR offering_registration_deadline_arg IS NULL
        OR course_id_arg IS NULL
        OR admin_id_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to add_course_offering() cannot contain NULL values.';
    END IF;

    /* Check if there is at least one session in the array */
    SELECT COUNT(*) INTO num_sessions FROM unnest(sessions_arr);
    IF (num_sessions < 1) THEN
        RAISE EXCEPTION 'There needs to to be at least 1 session';
    END IF;

    FOR counter in 1..num_sessions
    LOOP
        IF sessions_arr[counter].session_date IS NULL
            OR sessions_arr[counter].session_start_hour IS NULL
            OR sessions_arr[counter].room_id IS NULL
        THEN
            RAISE EXCEPTION 'Arguments (session details) to add_course_offering() cannot contain NULL values.';
        END IF;
    END LOOP;

    /* Extracting the start date and end date */
    SELECT MIN(session_date) INTO off_start_date FROM unnest(sessions_arr);
    SELECT MAX(session_date) INTO off_end_date FROM unnest(sessions_arr);

    SELECT c.course_duration INTO course_duration
    FROM Courses c
    WHERE course_id_arg = c.course_id;

    /* Checking the conditions of course offering */
    IF (offering_launch_date_arg > offering_registration_deadline_arg) THEN
        RAISE EXCEPTION 'Offering registration date cannot be earlier than launch date';
    ELSIF (offering_num_target_registration_arg < 0) THEN
        RAISE EXCEPTION 'Offering target registration should be more than or equal to 0';
    ELSIF (off_start_date > off_end_date) THEN
        RAISE EXCEPTION 'Offering end date cannot be earlier than start date';
    END IF;

    /* Inserting into course offering */
    /* Temporarily setting num target registration and seating capacity as 0 to pass check constraints first */
    /* seating capacity of course offering is updated in add_session(). */
    /* num target registration is update after all the sessions are added. */
    INSERT INTO CourseOfferings
    (offering_launch_date, offering_fees, offering_registration_deadline, offering_num_target_registration, offering_seating_capacity, course_id, admin_id, offering_start_date, offering_end_date)
    VALUES
    (offering_launch_date_arg, offering_fees_arg, offering_registration_deadline_arg, 0, 0, course_id_arg, admin_id_arg, off_start_date, off_end_date);

    /* Check if there is instructor for each session and check for session constraints */
    FOR counter in 1..num_sessions
    LOOP
        SELECT employee_id INTO instructor_id
        FROM get_available_instructors(course_id_arg, sessions_arr[counter].session_date, sessions_arr[counter].session_date)
        LIMIT 1;

        IF (instructor_id IS NULL) THEN
            RAISE EXCEPTION 'Offering does not have enough instructors for sessions.';
        END IF;

        session_end_hour := sessions_arr[counter].session_start_hour + course_duration;

        IF (sessions_arr[counter].session_start_hour >= 9 AND sessions_arr[counter].session_start_hour < 12 AND session_end_hour > 12) OR (sessions_arr[counter].session_start_hour > 18 OR session_end_hour > 18 OR sessions_arr[counter].session_start_hour < 9)
        THEN
            RAISE EXCEPTION 'Session time is out of range.';
        ELSIF sessions_arr[counter].room_id NOT IN (
            SELECT rid
            FROM find_rooms(sessions_arr[counter].session_date, sessions_arr[counter].session_start_hour, course_duration)
        ) THEN
            RAISE EXCEPTION 'Room % in use.', sessions_arr[counter].room_id;
        END IF;

        IF counter <> (SELECT add_session(course_id_arg, offering_launch_date_arg, counter, sessions_arr[counter].session_date, sessions_arr[counter].session_start_hour, instructor_id, sessions_arr[counter].room_id))
        THEN
            RAISE EXCEPTION 'Failed to add session successfully.';
        END IF;
    END LOOP;

    SELECT co.offering_seating_capacity INTO final_offering_seating_capacity
    FROM CourseOfferings co
    WHERE co.offering_launch_date = offering_launch_date_arg
        AND co.course_id = course_id_arg;

    IF (final_offering_seating_capacity < offering_num_target_registration_arg) THEN
        RAISE EXCEPTION 'Capacity is less than target number of registration';
    END IF;

    /* Finally, update course offering to have the right offering_num_target_registration value after all sessions are added */
    UPDATE CourseOfferings co
    SET offering_num_target_registration = offering_num_target_registration_arg
    WHERE co.offering_launch_date = offering_launch_date_arg
        AND co.course_id = course_id_arg;

    SELECT * INTO new_course_offering
    FROM CourseOfferings co
    WHERE co.offering_launch_date = offering_launch_date_arg
        AND co.course_id = course_id_arg;

    offering_launch_date := new_course_offering.offering_launch_date;
    offering_fees := new_course_offering.offering_fees;
    offering_registration_deadline := new_course_offering.offering_registration_deadline;
    offering_num_target_registration := new_course_offering.offering_num_target_registration;
    offering_seating_capacity := new_course_offering.offering_seating_capacity;
    course_id := new_course_offering.course_id;
    admin_id := new_course_offering.admin_id;
    offering_start_date := new_course_offering.offering_start_date;
    offering_end_date := new_course_offering.offering_end_date;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;
