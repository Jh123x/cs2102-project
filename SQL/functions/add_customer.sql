CREATE OR REPLACE PROCEDURE add_customer (
    name TEXT,
    phone INTEGER,
    address TEXT,
    email TEXT,
    credit_card_number CHAR(16),
    cvv CHAR(3),
    expiry_date DATE,
    from_date DATE
    ) AS $$
DECLARE 
    curr_id INTEGER;
BEGIN
    SELECT max(cust_id) + 1 INTO curr_id FROM Customers;
    INSERT INTO Credit_cards VALUES (number, cvv, expiry_date, from_date);
    INSERT INTO Customers VALUES (curr_id, phone, address, name, email);
END;
$$ LANGUAGE plpgsql;