DROP TABLE IF EXISTS Credit_cards CASCADE;
CREATE TABLE Credit_cards (
    number CHAR(16) PRIMARY KEY,
    cvv CHAR(3),
    expiry_date DATE,
    from_date DATE
);