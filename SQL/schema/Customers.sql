DROP TABLE IF EXISTS Customers CASCADE;
CREATE TABLE Customers (
    customer_id SERIAL PRIMARY KEY,
    phone INTEGER,
    address TEXT,
    name TEXT,
    email TEXT,

    CHECK(email ~ '.+@.+\..+'),
    CHECK(phone > 0)
);

DROP TABLE IF EXISTS CreditCards CASCADE;
CREATE TABLE CreditCards (
    number CHAR(16) PRIMARY KEY,
    cvv CHAR(3),
    expiry_date DATE,

    CHECK (number ~ '[0-9]{16}'),
    CHECK (cvv ~ '[0-9]{3}')
);
