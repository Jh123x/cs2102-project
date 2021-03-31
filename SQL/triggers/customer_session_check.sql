CREATE OR REPLACE FUNCTION customer_session_check() RETURNS TRIGGER AS $$
    DECLARE
        register_count INTEGER;
        redeem_count INTEGER;
        cancel_count INTEGER;
    BEGIN
        IF (TG_OP = 'UPDATE' AND NEW.cust_id = OLD.cust_id AND NEW.course_id = OLD.course_id) THEN
            RETURN NEW;
        END IF;
        SELECT COUNT(*) INTO register_count FROM Registers WHERE NEW.cust_id = cust_id AND NEW.course_id = course_id;
        SELECT COUNT(*) INTO redeem_count FROM Redeems WHERE NEW.cust_id = cust_id AND NEW.course_id = course_id;
        SELECT COUNT(*) INTO cancel_count FROM Cancels WHERE NEW.cust_id = cust_id AND NEW.course_id = course_id;
        IF (register_count + redeem_count - cancels > 0) THEN
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