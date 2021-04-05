/*
    19. update_course_session: This routine is used when a customer requests to change a registered course session to another session.
    The inputs to the routine include the following:
        customer identifier,
        course offering identifier,
        and new session number.
    If the update request is valid and there is an available seat in the new session, the routine will process the request with the necessary updates.
*/
DROP FUNCTION IF EXISTS update_course_session CASCADE;
CREATE OR REPLACE FUNCTION update_course_session (
    customer_id             INTEGER,
    course_id               INTEGER,
    offering_launch_date    DATE,
    new_session_id          INTEGER
) RETURNS VOID
AS $$
DECLARE
    enroll_date         DATE;
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

    SELECT e.enroll_date, e.session_id, e.table_name INTO enroll_date, old_session_id, enrolment_table
    FROM Enrolment e
    WHERE customer_id = e.customer_id AND course_id = e.course_id AND offering_launch_date = e.offering_launch_date;

    IF e.enroll_date IS NULL THEN
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
        WHERE r.register_date = enroll_date;
    ELSE
        UPDATE Redeems r
        SET r.session_id = new_session_id
        WHERE r.redeem_date = enroll_date;
    END IF;
END;
$$ LANGUAGE plpgsql;
