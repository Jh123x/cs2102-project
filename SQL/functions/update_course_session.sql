/*
This routine is used when a customer requests to change a registered course session to another session.
The inputs to the routine include the following: customer identifier, course offering identifier, and new session number.
If the update request is valid and there is an available seat in the new session,
    the routine will process the request with the necessary updates.
*/
CREATE OR REPLACE PROCEDURE update_course_session (
    customer_id             INTEGER,
    course_id               INTEGER,
    offering_launch_date    DATE,
    new_session_id          INTEGER
) AS $$
DECLARE
    old_session_id      INTEGER;
    enrolment_table     TEXT;
    num_seats_available INTEGER;
    new_session_count   INTEGER;
BEGIN
    SELECT COUNT(*) INTO new_session_count
    FROM Sessions s
    WHERE course_id = s.course_id AND offering_launch_date = s.offering_launch_date AND new_session_id = s.session_id;

    IF new_session_count = 0 THEN
        RAISE EXCEPTION 'Requested new session does not exist.';
    END IF;

    SELECT e.session_id, e.table_name INTO old_session_id, enrolment_table
    FROM Enrolment e
    WHERE customer_id = e.customer_id AND course_id = e.course_id AND offering_launch_date = e.offering_launch_date;

    IF old_session_id IS NULL THEN
        RAISE EXCEPTION 'Customer is not registered to any session for this course offering.';
    END IF;

    SELECT r.room_seating_capacity - c.num_enrolled INTO num_seats_available
    FROM Sessions s NATURAL JOIN Rooms r NATURAL JOIN EnrolmentCount c
    WHERE course_id = s.course_id AND offering_launch_date = s.offering_launch_date AND new_session_id = s.session_id;

    IF num_seats_available = 0 THEN
        RAISE EXCEPTION 'Customer cannot change to this session because there are no seats remaining in the room.';
    END IF;

    IF enrolment_table = 'registers' THEN
        UPDATE Registers r
        SET r.session_id = new_session_id
        WHERE r.customer_id = customer_id
              AND r.course_id = course_id
              AND r.offering_launch_date = offering_launch_date
              AND r.session_id = old_session_id;
    ELSE
        UPDATE Redeems r
        SET r.session_id = new_session_id
        WHERE r.customer_id = customer_id
              AND r.course_id = course_id
              AND r.offering_launch_date = offering_launch_date
              AND r.session_id = old_session_id;
    END IF;
END;
$$ LANGUAGE plpgsql;
