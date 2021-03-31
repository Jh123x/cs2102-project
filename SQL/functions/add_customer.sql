CREATE OR REPLACE FUNCTION add_customer (
    name TEXT,
    phone INTEGER,
    address TEXT,
    email TEXT,
    credit_card_number CHAR(16),
    cvv CHAR(3),
    expiry_date DATE
)
RETURNS TABLE (customer_id INTEGER) AS $$
BEGIN
    /* Insert values into credit card */
    INSERT INTO CreditCards (number, cvv, expiry_date) VALUES (number, cvv, expiry_date);

    /* Insert customer values with auto generated id */
    INSERT INTO Customers (phone, address, name, email) VALUES (phone, address, name, email)
    RETURNING * INTO new_customer;

    customer_id := new_customer.customer_id;

    /* Match the credit card into the owner */
    INSERT INTO Owns (customer_id, number, from_date) VALUES (customer_id, number, CURRENT_DATE);
END;
$$ LANGUAGE plpgsql;
