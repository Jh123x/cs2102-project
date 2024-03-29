/*
    Triggers for Customers Table:
    - Total Participation
*/

CREATE OR REPLACE FUNCTION customers_total_participation_check()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS(SELECT customer_id FROM Customers EXCEPT SELECT customer_id FROM Owns)
    THEN
        RAISE EXCEPTION 'Total participation constraint violated on Customers.customer_id -- customer_id should exist in at least one record of Owns relation.';
        ROLLBACK;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS customers_total_participation ON Customers;
CREATE CONSTRAINT TRIGGER customers_total_participation
AFTER INSERT OR UPDATE OR DELETE ON Customers
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION customers_total_participation_check();

/*
    Triggers for CreditCards Table:
    - Total Participation
    - Key Constraint
*/

CREATE OR REPLACE FUNCTION credit_cards_key_constraint_check()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS(SELECT credit_card_number FROM Owns GROUP BY credit_card_number HAVING COUNT(credit_card_number) > 1)
    THEN
        RAISE EXCEPTION 'Key constraint violated on CreditCards.credit_card_number -- credit_card_number should exist in at most one record of Owns relation.';
        ROLLBACK;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS credit_cards_key_constraint ON CreditCards;
CREATE CONSTRAINT TRIGGER credit_cards_key_constraint
AFTER INSERT OR UPDATE OR DELETE ON CreditCards
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION credit_cards_key_constraint_check();

CREATE OR REPLACE FUNCTION credit_cards_total_participation_check()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS(SELECT credit_card_number FROM CreditCards EXCEPT SELECT credit_card_number FROM Owns)
    THEN
        RAISE EXCEPTION 'Total participation constraint violated on CreditCards.credit_card_number -- credit_card_number should exist in at least one record of Owns relation.';
        ROLLBACK;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS credit_cards_total_participation ON CreditCards;
CREATE CONSTRAINT TRIGGER credit_cards_total_participation_constraint
AFTER INSERT OR UPDATE OR DELETE ON CreditCards
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION credit_cards_total_participation_check();

/*
    Triggers for Owns Table:
    - Total Participation (Customers)
    - Total Participation (CreditCards)
    - Key Constraint (CreditCards)
*/

DROP TRIGGER IF EXISTS customers_total_participation ON Owns;
CREATE CONSTRAINT TRIGGER customers_total_participation_constraint
AFTER INSERT OR UPDATE OR DELETE ON Owns
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION customers_total_participation_check();

DROP TRIGGER IF EXISTS credit_cards_key_constraint ON Owns;
CREATE CONSTRAINT TRIGGER credit_cards_key_constraint
AFTER INSERT OR UPDATE OR DELETE ON Owns
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION credit_cards_key_constraint_check();

/*
    -- Test case
    BEGIN TRANSACTION;

    TRUNCATE Customers CASCADE;
    TRUNCATE CreditCards CASCADE;

    INSERT INTO Customers (customer_id, customer_phone, customer_address, customer_name, customer_email) VALUES (1, 1, 'a', 'b', 'a@b.com');
    INSERT INTO CreditCards (credit_card_number, credit_card_cvv, credit_card_expiry_date) VALUES ('1234567890123456', '123', CURRENT_DATE);
    INSERT INTO Owns (customer_id, credit_card_number, own_from_timestamp) VALUES ('1', '1234567890123456', CURRENT_DATE);

    INSERT INTO Customers (customer_id, customer_phone, customer_address, customer_name, customer_email) VALUES (2, 1, 'a', 'b', 'a@b.com');
    INSERT INTO CreditCards (credit_card_number, credit_card_cvv, credit_card_expiry_date) VALUES ('1234567890123457', '123', CURRENT_DATE);
    INSERT INTO Owns (customer_id, credit_card_number, own_from_timestamp) VALUES ('2', '1234567890123457', CURRENT_DATE);
    COMMIT;

    -- Below should fail
    INSERT INTO Owns (customer_id, credit_card_number, own_from_timestamp) VALUES ('1', '1234567890123457', CURRENT_DATE);
    UPDATE Owns Set customer_id = 1 WHERE customer_id = 2;
    DELETE FROM Owns;
*/
