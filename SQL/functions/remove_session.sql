/*
 This routine is used to remove a course session.
 The inputs to the routine include the following:
    course offering identifier
    session number

If the course session has not yet started and the request is valid,
    the routine will process the request with the necessary updates.
The request must not be performed if there is at least one registration for the session.

Note that the resultant seating capacity of the course offering
    could fall below the course offering’s target number of registrations, which is allowed.
*/
CREATE OR REPLACE PROCEDURE remove_session(
    course_id               INTEGER,
    offering_launch_date    INTEGER,
    session_id              INTEGER
) AS $$
DECLARE
    session_date            DATE;
    session_start_hour      DATE;
    room_seating_capacity   INTEGER;
    enrolment_count         INTEGER;
BEGIN
    SELECT s.session_date, s.session_start_hour, r.room_seating_capacity
        INTO session_date, session_start_hour, room_seating_capacity
    FROM Sessions s NATURAL JOIN Rooms r
    WHERE s.course_id = course_id AND s.offering_launch_date AND s.session_id = session_id;

    IF session_date IS NULL THEN
        RAISE EXCEPTION 'Given session does not exist.';
    END IF;

    IF (CURRENT_DATE > session_date)
        OR (CURRENT_DATE = session_date AND EXTRACT(HOUR FROM NOW()) >= session_start_hour) THEN
        RAISE EXCEPTION 'Cannot remove session that has already started.';
    END IF;

    SELECT COUNT(*) INTO enrolment_count
    FROM Enrolment e
    WHERE e.course_id = course_id AND e.offering_launch_date AND e.session_id = session_id;

    IF (enrolment_count > 0) THEN
        RAISE EXCEPTION 'Cannot remove session that has at least one student.';
    END IF;

    DELETE FROM Sessions s
    WHERE s.course_id = course_id AND s.offering_launch_date AND s.session_id = session_id;

    UPDATE CourseOfferings c
    SET c.offering_seating_capacity = c.offering_seating_capacity - room_seating_capacity
    WHERE c.course_id = course_id AND c.offering_launch_date;
END;
$$ LANGUAGE plpgsql;
