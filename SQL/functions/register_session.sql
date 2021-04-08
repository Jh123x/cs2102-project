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
    offering_launch_date DATE,
    course_id_arg INTEGER,
    session_id_arg INTEGER,
    customer_id_arg INTEGER,
    payment_method TEXT
) RETURNS VOID
AS $$
DECLARE
    credit_card_number CHAR(16);
    buy_timestamp_arg TIMESTAMP;
    package_name TEXT;
    package_id_arg INTEGER;
    package_num_free_registrations INTEGER;
    num_red_duplicate INTEGER;
    num_reg_duplicate INTEGER;
    buy_num_remaining_redemptions_arg INTEGER;
BEGIN
    /* Check for NULLs in arguments */
    IF offering_launch_date IS NULL
        OR course_id_arg IS NULL
        OR session_id_arg IS NULL
        OR customer_id_arg IS NULL
        OR payment_method IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to register_session() cannot contain NULL values.';
    END IF;

    /*Check if the method is valid*/
    IF (payment_method NOT IN ('Redemption', 'Credit Card')) THEN
        RAISE EXCEPTION 'Invalid payment type';
    END IF;
    
    SELECT COUNT(*) INTO num_red_duplicate
    FROM Redeems r 
    JOIN Buys b
    ON b.buy_timestamp = r.buy_timestamp
    WHERE b.customer_id = customer_id_arg
    AND r.course_id = course_id_arg
    AND r.session_id = session_id_arg;

    IF (num_red_duplicate > 0) THEN
        RAISE EXCEPTION 'Session has been redeemed!';
    END IF;

    IF (payment_method = 'Redemption') THEN        
        SELECT b.buy_timestamp, b.package_id ,b.buy_num_remaining_redemptions INTO buy_timestamp_arg, package_id_arg, buy_num_remaining_redemptions_arg
        FROM Buys b
        WHERE b.customer_id = customer_id_arg
        AND b.buy_num_remaining_redemptions >= 1
        ORDER BY b.buy_num_remaining_redemptions ASC
        LIMIT 1;
    END IF;

    IF (package_id_arg IS NULL AND payment_method = 'Redemption') THEN
        RAISE EXCEPTION 'No active packages!';
    END IF;

    IF (package_id_arg IS NOT NULL AND payment_method = 'Redemption') THEN
        UPDATE Buys
        SET buy_num_remaining_redemptions =  buy_num_remaining_redemptions_arg-1
        WHERE customer_id = customer_id_arg
        AND package_id = package_id_arg
        AND buy_timestamp = buy_timestamp_arg;

        INSERT INTO Redeems
        VALUES(statement_timestamp(), buy_timestamp_arg,session_id_arg,offering_launch_date,course_id_arg);
    END IF;

    SELECT o.credit_card_number INTO credit_card_number
    FROM Owns o
    WHERE o.customer_id = customer_id_arg;

    SELECT COUNT(*) INTO num_reg_duplicate
    FROM Registers r
    WHERE r.customer_id = customer_id_arg
    AND r.course_id = course_id_arg
    AND r.session_id = session_id_arg;

    IF (credit_card_number IS NULL) THEN 
        RAISE EXCEPTION 'Credit card is invalid';
    END IF;

    IF (num_reg_duplicate > 0) THEN
        RAISE EXCEPTION 'Session has been redeemed!';
    END IF;

    IF(payment_method = 'Credit Card') THEN
        INSERT INTO Registers(register_timestamp, customer_id, credit_card_number, session_id, offering_launch_date, course_id)
        VALUES (statement_timestamp(), customer_id_arg, credit_card_number, session_id_arg, offering_launch_date, course_id_arg);
    END IF;

END;
$$ LANGUAGE plpgsql;
