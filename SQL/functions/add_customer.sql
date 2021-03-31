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
    SELECT max(cust_id) + 1 INTO curr_id FROM Customers;
    INSERT INTO CreditCards (number, cvv, expiry_date) VALUES (number, cvv, expiry_date);
    INSERT INTO Customers (cust_id, phone, address, name, email) VALUES (curr_id, phone, address, name, email);
    INSERT INTO Owns (cust_id, number, from_date) VALUES (cust_id, number, CURRENT_DATE());
END;
$$ LANGUAGE plpgsql;
