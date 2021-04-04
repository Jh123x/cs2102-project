/*
    4. update_credit_card: This routine is used when a customer requests to change his/her credit card details.
    The inputs to the routine include
        the customer identifier and
        his/her new credit card details (credit card number, expiry date, CVV code).
*/
CREATE OR REPLACE FUNCTION update_credit_card (
    customer_id INTEGER,
    credit_card_number CHAR(16),
    credit_card_cvv CHAR(3),
    credit_card_expiry_date DATE
) RETURNS VOID
AS $$
BEGIN
    INSERT INTO CreditCards
    (credit_card_number, credit_card_cvv, credit_card_expiry_date)
    VALUES
    (credit_card_number, credit_card_cvv, credit_card_expiry_date);

    INSERT INTO Owns
    (customer_id, credit_card_number, own_from_date)
    VALUES
    (customer_id, credit_card_number, CURRENT_DATE);
END;
$$ LANGUAGE plpgsql;
