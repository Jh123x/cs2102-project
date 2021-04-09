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
    session_instructor_id INTEGER,
    session_room_id INTEGER
)
RETURNS TABLE (session_id INTEGER) AS $$
DECLARE
    new_package RECORD;
    session_end_hour INTEGER;
    session_offering_registration_deadline DATE;
    session_duration INTEGER;
    new_room_seating_capacity INTEGER;
BEGIN
    /* Check for NULLs in arguments */
    IF session_course_id IS NULL
        OR session_offering_launch_date IS NULL
        OR session_number IS NULL
        OR session_date IS NULL
        OR session_start_hour IS NULL
        OR session_instructor_id IS NULL
        OR session_room_id IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to add_session() cannot contain NULL values.';
    ELSIF NOT EXISTS(SELECT instructor_id FROM Instructors i WHERE i.instructor_id = session_instructor_id)
    THEN
        RAISE EXCEPTION 'Instructor ID % does not exists.', session_instructor_id;
    END IF;

    SELECT r.room_seating_capacity INTO new_room_seating_capacity
    FROM Rooms r
    WHERE r.room_id = session_room_id;

    IF new_room_seating_capacity IS NULL
    THEN
        RAISE EXCEPTION 'Room ID % does not exists.', session_room_id;
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

    SELECT course_duration INTO session_duration FROM Courses WHERE session_course_id = course_id;
    IF NOT EXISTS (SELECT rid FROM find_rooms(session_date, session_start_hour,session_duration ) WHERE rid = session_room_id)
    THEN 
        RAISE EXCEPTION 'Room % is in use', session_room_id;
    END IF;

    IF NOT EXISTS (SELECT employee_id FROM find_instructors(session_course_id,session_date,session_start_hour) WHERE employee_id = session_instructor_id)
    THEN
        RAISE EXCEPTION 'Instructor is not available';
    END IF;
    
    INSERT INTO Sessions
    (session_id, session_date, session_start_hour, session_end_hour, course_id, offering_launch_date, room_id, instructor_id)
    VALUES
    (session_id, session_date, session_start_hour, session_end_hour, session_course_id, session_offering_launch_date, session_room_id, session_instructor_id);

    UPDATE CourseOfferings co
    SET offering_seating_capacity = (offering_seating_capacity + new_room_seating_capacity)
    WHERE co.course_id = session_course_id
        AND co.offering_launch_date = session_offering_launch_date;
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;
