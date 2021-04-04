DROP TABLE IF EXISTS Customers CASCADE;
CREATE TABLE Customers (
    customer_id SERIAL PRIMARY KEY,
    customer_phone INTEGER NOT NULL,
    customer_address TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    customer_email TEXT NOT NULL,

    CHECK(customer_email ~ '.+@.+\..+'),
    CHECK(customer_phone > 0)
);

DROP TABLE IF EXISTS CreditCards CASCADE;
CREATE TABLE CreditCards (
    credit_card_number CHAR(16) PRIMARY KEY,
    credit_card_cvv CHAR(3) NOT NULL,
    credit_card_expiry_date DATE NOT NULL,

    CHECK (credit_card_number ~ '[0-9]{16}'),
    CHECK (credit_card_cvv ~ '[0-9]{3}')
);
