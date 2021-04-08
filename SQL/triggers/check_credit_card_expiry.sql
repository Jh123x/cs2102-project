DROP FUNCTION IF EXISTS get_credit_card_expiry CASCADE;
CREATE OR REPLACE FUNCTION get_credit_card_expiry (
    credit_card_number_arg CHAR(16)
) RETURNS DATE AS $$
BEGIN
    SELECT cc.credit_card_expiry_date
    FROM CreditCards cc
    WHERE cc.credit_card_number = credit_card_number_arg;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS credit_card_expiry_check CASCADE;
CREATE OR REPLACE FUNCTION credit_card_expiry_check()
RETURNS TRIGGER AS $$
DECLARE
BEGIN
    IF TG_TABLE_NAME ILIKE 'CreditCards' AND NEW.credit_card_expiry_date < CURRENT_DATE
    THEN
        RAISE EXCEPTION 'Cannot insert new credit card which already expired.';
    ELSIF TG_TABLE_NAME ILIKE 'Owns' AND get_credit_card_expiry(NEW.credit_card_number) < NEW.own_from_timestamp::DATE
    THEN
        RAISE EXCEPTION 'Cannot start owning a credit card which already expired.';
    ELSIF TG_TABLE_NAME ILIKE 'Buys' AND get_credit_card_expiry(NEW.credit_card_number) < NEW.buy_timestamp::DATE
    THEN
        RAISE EXCEPTION 'Cannot buy course package using a credit card which already expired.';
    ELSIF TG_TABLE_NAME ILIKE 'Registers' AND get_credit_card_expiry(NEW.credit_card_number) < NEW.register_timestamp::DATE
    THEN
        RAISE EXCEPTION 'Cannot register for a course session using a credit card which already expired.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS credit_card_expiry ON CreditCards;
CREATE CONSTRAINT TRIGGER credit_card_expiry
AFTER INSERT OR UPDATE ON CreditCards
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION credit_card_expiry_check();

DROP TRIGGER IF EXISTS credit_card_expiry ON Owns;
CREATE CONSTRAINT TRIGGER credit_card_expiry
AFTER INSERT OR UPDATE ON Owns
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION credit_card_expiry_check();

DROP TRIGGER IF EXISTS credit_card_expiry ON Buys;
CREATE CONSTRAINT TRIGGER credit_card_expiry
AFTER INSERT OR UPDATE ON Buys
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION credit_card_expiry_check();

DROP TRIGGER IF EXISTS credit_card_expiry ON Registers;
CREATE CONSTRAINT TRIGGER credit_card_expiry
AFTER INSERT OR UPDATE ON Registers
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION credit_card_expiry_check();
