/*
    17. register_session: This routine is used when a customer requests to register for a session in a course offering.
    The inputs to the routine include the following:
        customer identifier,
        course offering identifier,
        session number, and
        payment method (credit card or redemption from active package).
    If the registration transaction is valid, this routine will process the registration with the necessary updates (e.g., payment/redemption).
*/
DROP FUNCTION IF EXISTS register_session CASCADE;
CREATE OR REPLACE FUNCTION register_session (
    offering_launch_date_arg DATE,
    course_id_arg INTEGER,
    session_id_arg INTEGER,
    customer_id_arg INTEGER,
    payment_method TEXT
) RETURNS BOOLEAN
AS $$
DECLARE
    credit_card_number CHAR(16);
    buy_timestamp_arg TIMESTAMP;
    package_id_arg INTEGER;
    buy_num_remaining_redemptions_arg INTEGER;
BEGIN
    /* Check for NULLs in arguments */
    IF offering_launch_date_arg IS NULL
        OR course_id_arg IS NULL
        OR session_id_arg IS NULL
        OR customer_id_arg IS NULL
        OR payment_method IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to register_session() cannot contain NULL values.';
    END IF;

    /* Check if session to be registered/redeemed exists */
    IF NOT EXISTS(
        SELECT session_id FROM Sessions s
        WHERE s.offering_launch_date = offering_launch_date_arg;
            AND s.course_id = course_id_arg
            AND s.session_id = session_id_arg
    ) THEN
        RAISE EXCEPTION 'Session does not exist.';
    END IF;

    /* Check if customer exists */
    IF NOT EXISTS(SELECT customer_id FROM Customers c WHERE c.customer_id = customer_id_arg)
    THEN
        RAISE EXCEPTION 'Customer ID % does not exist.', customer_id_arg;
    END IF;

    /* Check if the payment method is valid */
    IF (payment_method NOT IN ('Redemption', 'Credit Card')) THEN
        RAISE EXCEPTION 'Invalid payment type';
    END IF;

    /* Check if customer has an active registration/redemtpion of course session */
    IF EXISTS(
        SELECT e.enroll_timestamp
        FROM Enrolment e
        WHERE e.customer_id = customer_id_arg
            AND e.offering_launch_date = offering_launch_date_arg;
            AND e.course_id = course_id_arg
            AND e.session_id = session_id_arg
    ) THEN
        RAISE EXCEPTION 'Customer has already enrolled (either registered or redeemed) this session!';
    END IF;

    IF payment_method = 'Redemption'
    THEN
        SELECT b.buy_timestamp, b.package_id ,b.buy_num_remaining_redemptions
        INTO buy_timestamp_arg, package_id_arg, buy_num_remaining_redemptions_arg
        FROM Buys b
        WHERE b.customer_id = customer_id_arg
            AND b.buy_num_remaining_redemptions >= 1
            ORDER BY b.buy_num_remaining_redemptions ASC
            LIMIT 1;

        IF package_id_arg IS NULL
        THEN
            RAISE EXCEPTION 'No active packages!';

        UPDATE Buys
        SET buy_num_remaining_redemptions =  (buy_num_remaining_redemptions_arg - 1)
        WHERE customer_id = customer_id_arg
            AND package_id = package_id_arg
            AND buy_timestamp = buy_timestamp_arg;

        INSERT INTO Redeems
        (redeem_timestamp, buy_timestamp, session_id, offering_launch_date, course_id, redeem_cancelled)
        VALUES
        (statement_timestamp(), buy_timestamp_arg, session_id_arg, offering_launch_date_arg, course_id_arg);
    ELSE
        SELECT o.credit_card_number INTO credit_card_number
        FROM Owns o
        WHERE o.customer_id = customer_id_arg;

        IF credit_card_number IS NULL THEN
            RAISE EXCEPTION 'Credit card is invalid';
        END IF;

        INSERT INTO Registers
        (register_timestamp, customer_id, credit_card_number, session_id, offering_launch_date, course_id)
        VALUES
        (statement_timestamp(), customer_id_arg, credit_card_number, session_id_arg, offering_launch_date_arg, course_id_arg);
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
