CREATE OR REPLACE FUNCTION customer_redeems_check() RETURNS TRIGGER AS $$
    DECLARE
        redemptions_left INTEGER;
    BEGIN
        SELECT SUM(num_remaining_redemptions) INTO redemptions_left
        FROM Buys WHERE NEW.customer_id = customer_id;

        IF (redemptions_left <= 0) THEN 
            RAISE EXCEPTION 'There are no redemptions left for this customer';
        END IF; 

        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER customer_redeems_trigger
BEFORE INSERT ON Redeems
FOR EACH ROW EXECUTE FUNCTION customer_redeems_check();