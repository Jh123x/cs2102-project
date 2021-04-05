CREATE OR REPLACE FUNCTION customer_session_check()
RETURNS TRIGGER AS $$
DECLARE
    registration_deadline   DATE;
    register_count          INTEGER;
    redeem_count            INTEGER;
    cancel_count            INTEGER;
    new_cust_id INTEGER;
    old_cust_id INTEGER;
BEGIN

    /*Join the tables to obtain the customer for redeems*/
    IF (TG_TABLE_NAME = 'redeems') THEN
        SELECT b.customer_id INTO new_cust_id 
        FROM Redeems r
        JOIN Buys b
        ON r.buy_date = b.buy_date
        WHERE NEW.buy_date = b.buy_date
        LIMIT 1;
        SELECT b.customer_id INTO old_cust_id
        FROM Redeems r
        JOIN Buys b
        ON r.buy_date = b.buy_date
        WHERE NEW.buy_date = b.buy_date
        LIMIT 1;
    ELSE
        new_cust_id := NEW.customer_id;
        old_cust_id := OLD.customer_id;
    END IF;
    IF (TG_OP = 'UPDATE' AND new_cust_id = old_cust_id AND NEW.course_id = OLD.course_id) THEN
        RETURN NEW;
    END IF;

    SELECT c.offering_registration_deadline INTO registration_deadline
    FROM CourseOfferings c
    WHERE c.course_id = NEW.course_id AND c.offering_launch_date = NEW.offering_launch_date;

    IF CURRENT_DATE > registration_deadline THEN
        RAISE EXCEPTION 'Registration deadline for this session is over.';
    END IF;

    SELECT COUNT(*) INTO register_count 
    FROM Registers 
    WHERE new_cust_id = customer_id 
    AND NEW.course_id = course_id;

    SELECT COUNT(*) INTO redeem_count 
    FROM Redeems r
    JOIN Buys b
    ON b.buy_date = r.buy_date
    WHERE NEW.course_id = course_id
    AND b.customer_id = new_cust_id;
    IF (register_count > 0 OR redeem_count > 0) THEN
        RAISE EXCEPTION 'Already registered for a session of this course';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER customer_redeems_trigger
BEFORE INSERT OR UPDATE ON Redeems
FOR EACH ROW EXECUTE FUNCTION customer_session_check();

CREATE TRIGGER customer_register_trigger
BEFORE INSERT OR UPDATE ON Registers
FOR EACH ROW EXECUTE FUNCTION customer_session_check();
