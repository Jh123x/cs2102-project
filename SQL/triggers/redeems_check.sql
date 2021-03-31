-- Check if the customer purchased the package when 
-- inserting into redeems table
CREATE OR REPLACE FUNCTION redeems_check() RETURNS TRIGGER AS $$
    DECLARE
        redemptions_left INTEGER;
    BEGIN
        SELECT SUM(num_remaining_redemptions) INTO redemptions_left FROM Buys WHERE cust_id = NEW.cust_id;
        IF (redemptions_left <= 0) THEN
            RAISE EXCEPTION 'THERE IS NOTHING LEFT TO REDEEM';
        END IF;
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER redemption_check_trigger
BEFORE INSERT ON Redeems
FOR EACH ROW EXECUTE FUNCTION redeems_check();
