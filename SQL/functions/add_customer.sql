/*
    3. add_customer: This routine is used to add a new customer.
    The inputs to the routine include the following:
        name,
        home address,
        contact number,
        email address, and
        credit card details (credit card number, expiry date, CVV code).
    The customer identifier is generated by the system.
*/
DROP FUNCTION IF EXISTS add_customer CASCADE;
CREATE OR REPLACE FUNCTION add_customer (
    customer_name TEXT,
    customer_address TEXT,
    customer_phone INTEGER,
    customer_email TEXT,
    credit_card_number CHAR(16),
    credit_card_cvv CHAR(3),
    credit_card_expiry_date DATE
)
RETURNS TABLE (customer_id INTEGER) AS $$
DECLARE
    new_customer RECORD;
BEGIN
    /* Check for NULLs in arguments */
    IF customer_name IS NULL
        OR customer_address IS NULL
        OR customer_phone IS NULL
        OR customer_email IS NULL
        OR credit_card_number IS NULL
        OR credit_card_cvv IS NULL
        OR credit_card_expiry_date IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to add_customer() cannot contain NULL values.';
    END IF;

    /* Insert values into credit card */
    INSERT INTO CreditCards
    (credit_card_number, credit_card_cvv, credit_card_expiry_date)
    VALUES
    (credit_card_number, credit_card_cvv, credit_card_expiry_date);

    /* Insert customer values with auto generated id */
    INSERT INTO Customers 
    (customer_phone, customer_address, customer_name, customer_email)
    VALUES
    (customer_phone, customer_address, customer_name, customer_email)
    RETURNING * INTO new_customer;

    customer_id := new_customer.customer_id;

    /* Match the credit card into the owner */
    INSERT INTO Owns
    (customer_id, credit_card_number, own_from_timestamp)
    VALUES
    (customer_id, credit_card_number, CURRENT_DATE);

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;
