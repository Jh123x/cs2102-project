/*
    21. update_instructor: This routine is used to change the instructor for a course session.
    The inputs to the routine include the following:
        course offering identifier,
        session number, and
        identifier of the new instructor.
    If the course session has not yet started and the update request is valid, the routine will process the request with the necessary updates.
*/
DROP FUNCTION IF EXISTS update_instructor CASCADE;
CREATE OR REPLACE FUNCTION update_instructor (
    offering_launch_date_arg INTEGER,
    course_id_arg INTEGER,
    session_id_arg INTEGER,
    instructor_id_arg INTEGER
) RETURNS VOID
AS $$
DECLARE
    session_date DATE;
    session_start_hour INTEGER;
BEGIN
    /* Check for NULLs in arguments */
    IF offering_launch_date_arg IS NULL
        OR course_id_arg IS NULL
        OR session_id_arg IS NULL
        OR instructor_id_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to update_instructor() cannot contain NULL values.';
    END IF;

    SELECT s.session_date, s.session_start_hour INTO session_date, session_start_hour
    FROM Sessions s
    WHERE s.session_id = session_id_arg
        AND s.offering_launch_date = offering_launch_date_arg
        AND s.course_id = course_id_arg;

    /* Check if session identifier is valid */
    IF session_date IS NULL
    THEN
        RAISE EXCEPTION 'Session identifier supplied is invalid.';
    /* Check if employee ID is a valid instructor */
    ELSIF instructor_id_arg NOT IN (SELECT instructor_id FROM Instructors)
    THEN
        RAISE EXCEPTION 'Employee ID supplied is invalid (either not an instructor or the employee ID does not exist).';
    END IF;

    IF (session_start_hour >= EXTRACT(HOUR FROM CURRENT_TIME))
    THEN
        RAISE EXCEPTION 'Session already started! Cannot update instructor!';
    END IF;

    IF instructor_id_arg NOT IN (
        SELECT employee_id FROM find_instructors(offering_launch_date_arg, course_id_arg, session_date, session_start_hour)
    )
    THEN
        RAISE EXCEPTION 'This instructor cannot teach this session!';
    END IF;
END;
$$ LANGUAGE plpgsql;
