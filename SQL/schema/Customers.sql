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
    number CHAR(16) PRIMARY KEY, --Maybe can consider DEC(16,0) ? Can add a check constraint to see if number >= 1000 0000 0000 0000
    cvv CHAR(3), --Maybe can consider DEC(3,0) and add constraint to see number >= 100
    expiry_date DATE,
    from_date DATE
);