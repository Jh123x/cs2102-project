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
    course_id INTEGER,
    offering_launch_date DATE,
    session_number INTEGER,
    session_date DATE,
    session_start_hour INTEGER,
    session_end_hour INTEGER,
    instructor_id INTEGER,
    room_id INTEGER
)
RETURNS TABLE (session_id INTEGER) AS $$
DECLARE
    new_package RECORD;
    offering_registration_deadline DATE;
BEGIN
    session_id := session_number;

    IF EXISTS(
        SELECT s.session_id FROM Sessions s
        WHERE s.course_id = course_id
            AND s.offering_launch_date = offering_launch_date
            AND s.session_id = session_number
    )
    THEN
        RAISE EXCEPTION 'Session ID already exists for course offering.';
    END IF;

    SELECT offering_registration_deadline INTO offering_registration_deadline
    FROM CourseOfferings co
    WHERE co.offering_launch_date = offering_launch_date
        AND co.course_id = course_id;

    IF (CURRENT_DATE > offering_registration_deadline)
    THEN
        RAISE EXCEPTION 'Course registration deadline already passed.';
    END IF;

    /* Todo: check room availability */
    /* Todo: check instructor availability */

    INSERT INTO Sessions
    (session_id, session_date, session_start_hour, session_end_hour, course_id, offering_launch_date, room_id, instructor_id)
    VALUES
    (session_id, session_date, session_start_hour, session_end_hour, course_id, offering_launch_date, room_id, instructor_id);
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;
