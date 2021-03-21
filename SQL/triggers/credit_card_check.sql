CREATE OR REPLACE FUNCTION credit_card_check_on_table()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.credit_card LIKE '[0-9]{16}') THEN
        RETURN NULL;
    ELSE
        RETURN NEW;
    ENDIF;
END
$$ LANGUAGE plpgsql;


CREATE TRIGGER credit_card_check_customers
BEFORE INSERT OR UPDATE ON Customers
FOR EACH ROW EXECUTE FUNCTION credit_card_check_on_table();