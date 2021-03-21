-- TODO: Move to check() constraint in customer table
DROP FUNCTION IF EXISTS credit_card_check_on_table;
DROP TRIGGER IF EXISTS credit_card_check_customers_trigger;

CREATE OR REPLACE FUNCTION credit_card_check_on_table()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.number NOT LIKE '[0-9]{16}' OR NEW.cvv NOT LIKE '[0-9]{3}') THEN
        RETURN NULL;
    ELSE
        RETURN NEW;
    ENDIF;
END
$$ LANGUAGE plpgsql;


CREATE TRIGGER credit_card_check_customers_trigger
BEFORE INSERT OR UPDATE ON Customers
FOR EACH ROW EXECUTE FUNCTION credit_card_check_on_table();