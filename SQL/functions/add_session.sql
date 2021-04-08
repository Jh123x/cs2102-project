/*
    24. add_session: This routine is used to add a new session to a course offering.
    The inputs to the routine include the following:
        course offering identifier,
        new session number,
        new session day,
        new session start hour,
        instructor identifier for new session, and
        room identifier for new session.
    If the course offering's registration deadline has not passed and the the addition request is valid, the routine will process the request with the necessary updates.
*/
DROP FUNCTION IF EXISTS add_session CASCADE;
CREATE OR REPLACE FUNCTION add_session (
    session_course_id INTEGER,
    session_offering_launch_date DATE,
    session_number INTEGER,
    session_date DATE,
    session_start_hour INTEGER,
    instructor_id INTEGER,
    room_id INTEGER
)
RETURNS TABLE (session_id INTEGER) AS $$
DECLARE
    new_package RECORD;
    session_end_hour INTEGER;
    session_offering_registration_deadline DATE;
BEGIN
    /* Check for NULLs in arguments */
    IF session_course_id IS NULL
        OR session_offering_launch_date IS NULL
        OR session_number IS NULL
        OR session_date IS NULL
        OR session_start_hour IS NULL
        OR instructor_id IS NULL
        OR room_id IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to add_session() cannot contain NULL values.';
    END IF;

    session_id := session_number;

    /*Get the end hour from the courses*/
    SELECT session_start_hour + course_duration INTO session_end_hour FROM Courses
    WHERE course_id = session_course_id;

    IF EXISTS(
        SELECT s.session_id FROM Sessions s
        WHERE s.course_id = session_course_id
            AND s.offering_launch_date = session_offering_launch_date
            AND s.session_id = session_number
    )
    THEN
        RAISE EXCEPTION 'Session ID already exists for course offering.';
    END IF;

    SELECT offering_registration_deadline INTO session_offering_registration_deadline
    FROM CourseOfferings co
    WHERE co.offering_launch_date = session_offering_launch_date
        AND co.course_id = session_course_id;

    IF (CURRENT_DATE > session_offering_registration_deadline)
    THEN
        RAISE EXCEPTION 'Course registration deadline already passed.';
    END IF;

    /* Todo: check room availability */
    /* Todo: check instructor availability */

    INSERT INTO Sessions
    (session_id, session_date, session_start_hour, session_end_hour, course_id, offering_launch_date, room_id, instructor_id)
    VALUES
    (session_id, session_date, session_start_hour, session_end_hour, session_course_id, session_offering_launch_date, room_id, instructor_id);
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;
