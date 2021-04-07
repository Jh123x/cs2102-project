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
    r_customer_id             INTEGER,
    r_course_id               INTEGER,
    r_offering_launch_date    DATE,
    new_session_id          INTEGER
) RETURNS VOID
AS $$
DECLARE
    enroll_timestamp         TIMESTAMP;
    old_session_id      INTEGER;
    enrolment_table     TEXT;
    num_seats_available INTEGER;
    new_session_count INTEGER;
BEGIN
    /* Check for NULLs in arguments */
    IF r_customer_id IS NULL
        OR r_course_id IS NULL
        OR r_offering_launch_date IS NULL
        OR new_session_id IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to update_course_session() cannot contain NULL values.';
    END IF;

    SELECT s.session_date INTO new_session_count
        FROM Sessions s
        WHERE s.course_id = r_course_id
            AND s.offering_launch_date = r_offering_launch_date
            AND s.session_id = new_session_id;

    /* Check if session identifier supplied exists */
    IF (new_session_count IS NULL) THEN
        RAISE EXCEPTION 'Session not found. Check if the session identifier (course_id, offering_launch_date and session_id) are correct.';
    /* Check if customer identifier supplied exists */
    ELSIF NOT EXISTS(
        SELECT c.customer_id FROM Customers c
    ) THEN
        RAISE EXCEPTION 'Customer ID not found.';
    END IF;

    SELECT e.enroll_timestamp, e.session_id, e.table_name
    INTO enroll_timestamp, old_session_id, enrolment_table
    FROM Enrolment e
    WHERE e.customer_id = r_customer_id
        AND e.course_id = r_course_id
        AND e.offering_launch_date = r_offering_launch_date;

    IF enroll_timestamp IS NULL THEN
        RAISE EXCEPTION 'Customer is not registered to any session for this course offering.';
    END IF;

    SELECT (r.room_seating_capacity - c.num_enrolled) INTO num_seats_available
    FROM Sessions s NATURAL JOIN Rooms r NATURAL JOIN EnrolmentCount c
    WHERE s.course_id = r_course_id
        AND s.offering_launch_date = r_offering_launch_date
        AND s.session_id = new_session_id;

    IF num_seats_available = 0 THEN
        RAISE EXCEPTION 'Customer cannot change to this session because there are no seats remaining in the room.';
    END IF;

    IF enrolment_table = 'registers' THEN
        UPDATE Registers r
        SET r.session_id = new_session_id
        WHERE r.register_timestamp = enroll_timestamp;
    ELSE
        UPDATE Redeems r
        SET r.session_id = new_session_id
        WHERE r.redeem_timestamp = enroll_timestamp;
    END IF;
END;
$$ LANGUAGE plpgsql;
