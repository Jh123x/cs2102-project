/*
    23. remove_session: This routine is used to remove a course session.
    The inputs to the routine include the following:
        course offering identifier and
        session number.
    If the course session has not yet started and the request is valid, the routine will process the request with the necessary updates.
    The request must not be performed if there is at least one registration for the session.
    Note that the resultant seating capacity of the course offering could fall below the course offering's target number of registrations, which is allowed.

    Design Notes:
        Since each course offering consists of one or more sessions, if the session to be deleted is the only session of the course offering, the deletion request will NOT be processed.
*/
DROP FUNCTION IF EXISTS top_packages remove_session;
CREATE OR REPLACE FUNCTION remove_session (
    course_id_arg               INTEGER,
    offering_launch_date_arg    DATE,
    session_id_arg              INTEGER
) RETURNS VOID
AS $$
DECLARE
    session_date            DATE;
    session_start_hour      INTEGER;
    room_seating_capacity   INTEGER;
BEGIN
    SELECT s.session_date, s.session_start_hour, r.room_seating_capacity
        INTO session_date, session_start_hour, room_seating_capacity
    FROM Sessions s
    NATURAL JOIN Rooms r
    WHERE s.course_id = course_id_arg
        AND s.offering_launch_date = offering_launch_date_arg
        AND s.session_id = session_id_arg;

    IF session_date IS NULL THEN
        RAISE EXCEPTION 'Given session does not exist.';
    END IF;

    IF (CURRENT_DATE > session_date)
        OR (CURRENT_DATE = session_date AND EXTRACT(HOUR FROM NOW()) >= session_start_hour) THEN
        RAISE EXCEPTION 'Cannot remove session that has already started.';
    END IF;

    IF EXISTS(
        SELECT e.enroll_date
        FROM Enrolment e
        WHERE e.course_id = course_id_arg
            AND e.offering_launch_date = offering_launch_date_arg
            AND e.session_id = session_id_arg
    )
    THEN
        RAISE EXCEPTION 'Cannot remove session that has at least one student.';
    END IF;

    IF (
        SELECT COUNT(*)
        FROM Sessions s
        WHERE s.course_id = course_id_arg
        AND s.offering_launch_date = offering_launch_date_arg
    ) > 1 THEN
        RAISE EXCEPTION 'Cannot delete the only session of a course offering (each course offering must have at least one session).';
    END IF;

    DELETE FROM Sessions s
    WHERE s.course_id = course_id_arg
        AND s.offering_launch_date = offering_launch_date_arg
        AND s.session_id = session_id_arg;

    UPDATE CourseOfferings c
    SET c.offering_seating_capacity = (c.offering_seating_capacity - room_seating_capacity)
    WHERE s.course_id = course_id_arg
        AND s.offering_launch_date = offering_launch_date_arg;
END;
$$ LANGUAGE plpgsql;
