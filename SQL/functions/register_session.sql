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
    buy_date DATE;
    package_name TEXT;
    package_id INTEGER;
    package_num_free_registrations INTEGER;
    num_duplicate INTEGER;
    buy_num_remaining_redemptions INTEGER;
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

    SELECT o.credit_card_number INTO credit_card_number
    FROM Owns o
    WHERE o.customer_id = customer_id_arg;

    IF (payment_method = 'Redemption') THEN
        SELECT COALESCE(b.buy_date, NULL), COALESCE(b.package_id, NULL) ,COALESCE(b.buy_num_remaining_redemptions, NULL) INTO buy_date, package_id, buy_num_remaining_redemptions
        FROM Buys b
        WHERE b.customer_id = customer_id_arg
        AND b.buy_num_remaining_redemptions >= 1
        ORDER BY buy_num_remaining_redemptions ASC
        LIMIT 1;
    END IF;

    IF (package_id = NULL AND payment_method = 'Redemption') THEN
        RAISE EXCEPTION 'No active packages!';
    END IF;

    SELECT COUNT(*) INTO num_duplicate
    FROM Registers r
    WHERE r.customer_id = customer_id_arg
    AND r.course_id = course_id_arg
    AND r.session_id = session_id_arg;

    IF (num_duplicate > 0) THEN
        RAISE EXCEPTION 'Session has been redeemed!';
    END IF;

    IF(payment_method = 'Credit Card') THEN
        INSERT INTO Registers(register_date, customer_id, credit_card_number, session_id, offering_launch_date, course_id)
        VALUES (CURRENT_DATE, customer_id_arg, credit_card_number, session_id_arg, offering_launch_date, course_id_arg);
    END IF;

    IF (package_id <> NULL) THEN
        UPDATE Buys b
        SET b.buy_num_remaining_redemptions = buy_num_remaining_redemptions-1
        WHERE b.customer_id = customer_id_arg
        AND b.package_id = package_id
        AND b.buy_date = buy_date;

        INSERT INTO Redeems
        VALUES(CURRENT_DATE, customer_id_arg,package_id,session_id_arg,offering_launch_date,course_id);
    END IF;
END;
$$ LANGUAGE plpgsql;
