DROP FUNCTION IF EXISTS get_credit_card_expiry CASCADE;
CREATE OR REPLACE FUNCTION get_credit_card_expiry (
    credit_card_number_arg CHAR(16)
) RETURNS DATE AS $$
DECLARE
    expiry_date DATE;
BEGIN
    SELECT cc.credit_card_expiry_date INTO expiry_date
    FROM CreditCards cc
    WHERE cc.credit_card_number = credit_card_number_arg;
    
    RETURN expiry_date;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS credit_card_expiry_check CASCADE;
CREATE OR REPLACE FUNCTION credit_card_expiry_check()
RETURNS TRIGGER AS $$
DECLARE
    table_lower_name TEXT;
BEGIN
    table_lower_name := LOWER(TG_TABLE_NAME);

    CASE
        WHEN table_lower_name = 'creditcards' THEN
            IF (NEW.credit_card_expiry_date < CURRENT_DATE) THEN
                RAISE EXCEPTION 'Cannot insert new credit card which already expired.';
            END IF;
        WHEN table_lower_name = 'owns' THEN
            IF get_credit_card_expiry(NEW.credit_card_number) < NEW.own_from_timestamp::DATE THEN
                RAISE EXCEPTION 'Cannot start owning a credit card which already expired.';
            END IF;
        WHEN table_lower_name ='buys' THEN
            IF get_credit_card_expiry(NEW.credit_card_number) < NEW.buy_timestamp::DATE THEN
                RAISE EXCEPTION 'Cannot buy course package using a credit card which already expired.';
            END IF;
        WHEN table_lower_name = 'registers' THEN
            IF get_credit_card_expiry(NEW.credit_card_number) < NEW.register_timestamp::DATE THEN
                RAISE EXCEPTION 'Cannot register for a course session using a credit card which already expired.';
            END IF;
        ELSE
            RAISE EXCEPTION 'Trigger is not suppose to be applied on table %', TG_TABLE_NAME;
        END CASE;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS credit_card_expiry ON CreditCards;
CREATE TRIGGER credit_card_expiry
AFTER INSERT OR UPDATE ON CreditCards
FOR EACH ROW EXECUTE FUNCTION credit_card_expiry_check();

DROP TRIGGER IF EXISTS credit_card_expiry ON Owns;
CREATE TRIGGER credit_card_expiry
AFTER INSERT OR UPDATE ON Owns
FOR EACH ROW EXECUTE FUNCTION credit_card_expiry_check();

DROP TRIGGER IF EXISTS credit_card_expiry ON Buys;
CREATE TRIGGER credit_card_expiry
AFTER INSERT OR UPDATE ON Buys
FOR EACH ROW EXECUTE FUNCTION credit_card_expiry_check();

DROP TRIGGER IF EXISTS credit_card_expiry ON Registers;
CREATE TRIGGER credit_card_expiry
AFTER INSERT OR UPDATE ON Registers
FOR EACH ROW EXECUTE FUNCTION credit_card_expiry_check();
