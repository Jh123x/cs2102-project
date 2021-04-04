/*
This routine is used to change the instructor for a course session.
The inputs to the routine include the following:
    course offering identifier, session number, and identifier of the new instructor.
If the course session has not yet started and the update request is valid,
    the routine will process the request with the necessary updates.
*/
CREATE OR REPLACE FUNCTION update_instructor (
    offering_launch_date INTEGER,
    course_id INTEGER,
    session_id INTEGER,
    new_instructor_employee_id INTEGER
) RETURNS VOID
AS $$
DECLARE
    session_date DATE;
    session_start_hour INTEGER;
BEGIN
    SELECT s.session_date, s.session_start_hour INTO session_date, session_start_hour
    FROM Sessions s
    WHERE session_id = s.session_id
    AND offering_launch_date = s.offering_launch_date
    AND course_id = s.course_id;

    IF (session_start_hour >= EXTRACT(HOUR FROM CURRENT_TIME))
    THEN
        RAISE EXCEPTION 'Session already started! Cannot update instructor!';
    END IF;

    IF new_instructor_employee_id NOT IN
        (SELECT employee_id FROM find_instructors(offering_launch_date, course_id, session_date, session_start_hour))
    THEN
        RAISE EXCEPTION 'This instructor cannot teach this session!';
    END IF;
END;
$$ LANGUAGE plpgsql;
