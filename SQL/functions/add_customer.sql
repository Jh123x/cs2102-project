CREATE OR REPLACE PROCEDURE add_customer (
        cust_id INTEGER,
        phone INTEGER,
        address TEXT,
        name TEXT,
        email TEXT
    ) AS $$
INSERT INTO Customers
VALUES (cust_id, phone, address, name, email);
$$ LANGUAGE SQL