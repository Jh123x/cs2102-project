CREATE OR REPLACE PROCEDURE update_credit_card (
        cust_id INTEGER,
        number CHAR(16),
        cvv CHAR(3),
        expiry_date DATE
    ) AS $$
BEGIN
    INSERT INTO Credit_cards (number, cvv, expiry_date) VALUES (number, cvv, expiry_date);
    INSERT INTO Owns (cust_id, number, from_date) VALUES (cust_id, number, CURRENT_DATE());
END
$$ LANGUAGE SQL