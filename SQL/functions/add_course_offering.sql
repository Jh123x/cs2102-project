/*
    10. add_course_offering: This routine is used to add a new offering of an existing course.
    The inputs to the routine include the following:
        course offering identifier,
        course identifier,
        course fees,
        launch date,
        registration deadline,
        administrator's identifier,and
        information for each session (session date, session start hour, and room identifier).
    If the input course offering information is valid, the routine will assign instructors for the sessions.
    If a valid instructor assignment exists, the routine will perform the necessary updates to add the course offering;
        otherwise, the routine will abort the course offering addition.
    Note that the seating capacity of the course offering must be at least equal to the course offering's target number of registrations.

    Todo: need to also accept information for each session (session date, session start hour, and room identifier)
*/
DROP FUNCTION IF EXISTS add_course_offering CASCADE;
DROP TYPE IF EXISTS session_information;
CREATE TYPE session_information AS(
    session_date DATE,
    session_start_hour INTEGER,
    room_id INTEGER
);
CREATE OR REPLACE FUNCTION add_course_offering (
    offering_launch_date DATE,
    offering_fees NUMERIC,
    sessions_arr session_information[],
    offering_registration_deadline DATE,
    offering_num_target_registration INTEGER,
    offering_seating_capacity INTEGER,
    course_id INTEGER,
    admin_id INTEGER
)
RETURNS VOID AS $$
DECLARE
    offering_start_date DATE;
    offering_end_date DATE;
    num_duplicate INTEGER;
    num_sessions INTEGER;
    offering_start_record RECORD;
    instructor_id INTEGER;
    session_id INTEGER;
    r session_information;
BEGIN

    /*Checking the conditions of course offering*/
    IF (offering_start_date > offering_end_date) THEN
        RAISE EXCEPTION 'Offering end date cannot be earlier than start date';

    ELSIF (offering_launch_date > offering_registration_deadline) THEN
        RAISE EXCEPTION 'Offering registration date cannot be earlier than launch date';
    
    ELSIF (offering_seating_capacity < offering_num_target_registration) THEN
        RAISE EXCEPTION 'Offering seating capacity cannot be less than number of target registration';

    ELSIF (offering_num_target_registration < 0) THEN
        RAISE EXCEPTION 'Offering target registration should be more than or equal to 0';
    
    ELSIF (offering_start_date < offering_registration_deadline + INTEGER '10' ) THEN
        RAISE EXCEPTION 'Offering start date should be at least 10 days after the registration deadline ';
    END IF ;

    SELECT COUNT(*) INTO num_duplicate
    FROM CourseOfferings co
    WHERE co.offering_launch_date = offering_launch_date
    AND co.course_id = course_id;

    IF (num_duplicate > 0) THEN
        RAISE EXCEPTION 'Course offering has been launched! ';
    END IF ;
    
    INSERT INTO CourseOfferings
    (offering_launch_date, offering_fees, offering_registration_deadline, offering_num_target_registration, offering_seating_capacity, course_id, admin_id, offering_start_date, offering_end_date)
    VALUES
    (offering_launch_date, offering_fees, offering_registration_deadline, offering_num_target_registration, offering_seating_capacity, course_id, admin_id, offering_start_date, offering_end_date);
    
    
    SELECT COUNT(*) INTO num_sessions FROM unnest(sessions_arr);
    offering_start_date := sessions_arr[1][1];
    offering_end_date := sessions_arr[1][1];
    session_id := 1;
    FOREACH r SLICE 1 in ARRAY sessions_arr
    LOOP
        IF (r[1] <= offering_start_date) THEN
            offering_start_date := r[1];
        END IF;
        IF (r[1] >= offering_end_date) THEN
            offering_end_date := r[1];
        END IF;
        SELECT employee_id INTO instructor_id FROM get_available_instructors(course_id,offering_start_date,offering_end_date) LIMIT 1;
        SELECT add_session(course_id,offering_launch_date,session_id,r[1],r[2],instructor_id,r[3]);
        session_id := session_id + 1;
    END LOOP;

END;
$$ LANGUAGE plpgsql;
