DROP TABLE IF EXISTS Customers CASCADE;
CREATE TABLE Customers (
    cust_id INTEGER PRIMARY KEY,
    phone INTEGER,
    address TEXT,
    name TEXT,
    email TEXT,
    CHECK(email LIKE '%@%'),
    CHECK(phone > 0)
);

DROP TABLE IF EXISTS Credit_cards CASCADE;
CREATE TABLE Credit_cards (
    number CHAR(16) PRIMARY KEY,
    cvv CHAR(3),
    expiry_date DATE
    CHECK (number LIKE '[0-9]{16}'),
    CHECK (cvv LIKE '[0-9]{3}')
);