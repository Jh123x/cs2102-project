/*
This routine is used to change the instructor for a course session.
The inputs to the routine include the following:
    course offering identifier, session number, and identifier of the new instructor.
If the course session has not yet started and the update request is valid,
    the routine will process the request with the necessary updates.
*/
CREATE OR REPLACE PROCEDURE update_instructor(
    course_offering_id INTEGER,
    session_number INTEGER,
    new_instructor_employee_id INTEGER
) AS $$
DECLARE
    session_date DATE;
    session_start_time TIMESTAMP;
BEGIN
    SELECT s.date, s.start_time INTO session_date, session_start_time
    FROM Sessions s
    WHERE sid = s.session_number;

    IF (session_start_time >= CURRENT_TIME) THEN
        RAISE EXCEPTION 'Session already started! Cannot update instructor!';
    END IF;

    IF new_instructor_employee_id NOT IN
        (SELECT employee_id FROM find_instructors(course_id, session_date, session_start_hour)) THEN
        RAISE EXCEPTION 'This instructor cannot teach this session!';
    END IF;
END;
$$ LANGUAGE plpgsql;
