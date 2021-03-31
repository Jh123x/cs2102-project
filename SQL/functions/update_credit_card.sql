CREATE OR REPLACE PROCEDURE update_credit_card (
    customer_id INTEGER,
    number CHAR(16),
    cvv CHAR(3),
    expiry_date DATE
) AS $$
BEGIN
    INSERT INTO CreditCards (number, cvv, expiry_date) VALUES (number, cvv, expiry_date);
    INSERT INTO Owns (customer_id, number, from_date) VALUES (customer_id, number, CURRENT_DATE);
END;
$$ LANGUAGE plpgsql;
