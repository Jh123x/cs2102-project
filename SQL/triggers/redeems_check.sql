/* Check if the customer purchased the package when */
/* inserting into redeems table */
CREATE OR REPLACE FUNCTION redeems_check()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COALESCE(SUM(buy_num_remaining_redemptions),0) FROM Buys WHERE buy_date = NEW.buy_date) <= 0 THEN
        RAISE EXCEPTION 'THERE IS NOTHING LEFT TO REDEEM';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER redemption_check_trigger
BEFORE INSERT ON Redeems
FOR EACH ROW EXECUTE FUNCTION redeems_check();
