DROP FUNCTION IF EXISTS add_customer CASCADE;
CREATE OR REPLACE FUNCTION add_customer (
    customer_name TEXT,
    customer_phone INTEGER,
    customer_address TEXT,
    customer_email TEXT,
    credit_card_number CHAR(16),
    credit_card_cvv CHAR(3),
    credit_card_expiry_date DATE
)
RETURNS TABLE (customer_id INTEGER) AS $$
DECLARE
    new_customer RECORD;
BEGIN
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
    (customer_id, credit_card_number, own_from_date)
    VALUES
    (customer_id, credit_card_number, CURRENT_DATE);

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;
