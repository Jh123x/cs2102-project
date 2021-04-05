DROP FUNCTION IF EXISTS customer_redeems_check CASCADE;
CREATE OR REPLACE FUNCTION customer_redeems_check()
RETURNS TRIGGER AS $$
DECLARE
    num_remaining_redemptions INTEGER;
BEGIN
    SELECT SUM(buy_num_remaining_redemptions) INTO num_remaining_redemptions
    FROM Buys
    WHERE NEW.buy_date = buy_date;

    IF (num_remaining_redemptions <= 0) THEN
        RAISE EXCEPTION 'There are no redemptions left for this customer';
    END IF; 

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER customer_redemption_trigger
BEFORE INSERT ON Redeems
FOR EACH ROW EXECUTE FUNCTION customer_redeems_check();
