DROP TABLE IF EXISTS Customers CASCADE;
DROP TABLE IF EXISTS Credit_cards CASCADE;
CREATE TABLE Customers (
    cust_id INTEGER PRIMARY KEY,
    phone INTEGER,
    address TEXT,
    name TEXT,
    email TEXT
);
CREATE TABLE Credit_cards (
    number CHAR(16) PRIMARY KEY,
    cvv CHAR(3),
    expiry_date DATE,
    from_date DATE
);