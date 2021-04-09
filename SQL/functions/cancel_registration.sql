/*
    20. cancel_registration: This routine is used when a customer requests to cancel a registered course session.
    The inputs to the routine include the following:
        customer identifier, and
        course offering identifier.
    If the cancellation request is valid, the routine will process the request with the necessary updates.
*/
DROP FUNCTION IF EXISTS cancel_registration CASCADE;
CREATE OR REPLACE FUNCTION cancel_registration (
    customer_id_arg             INTEGER,
    course_id_arg               INTEGER,
    offering_launch_date_arg    DATE
) RETURNS VOID
AS $$
DECLARE
    enroll_timestamp    TIMESTAMP;
    r_session_id        INTEGER;
    enrolment_table     TEXT;
    offering_fees       DEC(64, 2);
    session_date        DATE;
    refund_amt          DEC(64,2);
    package_credit      INTEGER;
    buy_timestamp_var   TIMESTAMP;
BEGIN
    /* Check for NULLs in arguments */
    IF customer_id_arg IS NULL
        OR course_id_arg IS NULL
        OR offering_launch_date_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to cancel_registration() cannot contain NULL values.';
    ELSIF NOT EXISTS(SELECT customer_id FROM Customers c WHERE c.customer_id = customer_id_arg)
    THEN
        RAISE EXCEPTION 'Customer ID % does not exist.', customer_id_arg;
    ELSIF NOT EXISTS(
        SELECT offering_launch_date FROM CourseOfferings co
        WHERE co.course_id = course_id_arg
            AND co.offering_launch_date = offering_launch_date_arg
    ) THEN
        RAISE EXCEPTION 'Course offering specified does not exist.';
    END IF;

    SELECT e.enroll_timestamp, e.session_id, e.table_name INTO enroll_timestamp, r_session_id, enrolment_table
    FROM Enrolment e
    WHERE e.customer_id = customer_id_arg
        AND e.course_id = course_id_arg
        AND e.offering_launch_date = offering_launch_date_arg;

    IF enroll_timestamp IS NULL THEN
        RAISE EXCEPTION 'Customer did not register for this course offering.';
    END IF;

    SELECT c.offering_fees, s.session_date INTO offering_fees, session_date
    FROM Sessions s NATURAL JOIN CourseOfferings c
    WHERE s.course_id = course_id_arg AND s.offering_launch_date = offering_launch_date_arg AND s.session_id = r_session_id;

    IF enrolment_table = 'registers' THEN
        UPDATE Registers r
        SET register_cancelled = true
        WHERE r.register_timestamp = enroll_timestamp;

        IF CURRENT_DATE <= session_date - interval '7 days' THEN
            refund_amt := 0.90 * offering_fees;
        ELSE
            refund_amt := 0;
        END IF;

        INSERT INTO Cancels
        (cancel_timestamp, cancel_refund_amount, cancel_package_credit, course_id, session_id, offering_launch_date, customer_id)
        VALUES
        (statement_timestamp(), refund_amt, NULL, course_id_arg, r_session_id, offering_launch_date_arg, customer_id_arg);
    ELSE
        UPDATE Redeems r
        SET redeem_cancelled = true
        WHERE r.redeem_timestamp = enroll_timestamp;

        IF CURRENT_DATE <= session_date - interval '7 days' THEN
            package_credit := 1;

            /* Refund the redeemed session by incrementing customer's Buys.num_remaining_redemptions */
            SELECT b.buy_timestamp INTO buy_timestamp_var
            FROM Redeems r
            NATURAL JOIN Buys b
            WHERE r.redeem_timestamp = enroll_timestamp
            LIMIT 1;

            UPDATE Buys
            SET buy_num_remaining_redemptions = (buy_num_remaining_redemptions + 1)
            WHERE buy_timestamp = buy_timestamp_var;
        ELSE
            package_credit := 0;
        END IF;

        INSERT INTO Cancels
        (cancel_timestamp, cancel_refund_amount, cancel_package_credit, course_id, session_id, offering_launch_date, customer_id)
        VALUES
        (statement_timestamp(), NULL, package_credit, course_id_arg, r_session_id, offering_launch_date_arg, customer_id_arg);
    END IF;
END;
$$ LANGUAGE plpgsql;
