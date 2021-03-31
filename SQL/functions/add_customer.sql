CREATE OR REPLACE PROCEDURE add_customer (
    name TEXT,
    phone INTEGER,
    address TEXT,
    email TEXT,
    credit_card_number CHAR(16),
    cvv CHAR(3),
    expiry_date DATE
    ) AS $$
DECLARE
    curr_id INTEGER;
BEGIN
    /* Insert values into credit card */
    INSERT INTO CreditCards (number, cvv, expiry_date) VALUES (number, cvv, expiry_date);

    /* Insert customer values with auto generated id */
    INSERT INTO Customers (phone, address, name, email) VALUES (phone, address, name, email);

    /* Get the new id that was added */
    SELECT cust_id INTO curr_id FROM Customers c WHERE c.phone = phone AND c.address = address AND c.name = name AND c.email = email;

    /* Match the credit card into the owner */
    INSERT INTO Owns (cust_id, number, from_date) VALUES (curr_id, number, CURRENT_DATE());
END;
$$ LANGUAGE plpgsql;
