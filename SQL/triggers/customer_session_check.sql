CREATE OR REPLACE FUNCTION customer_session_check()
RETURNS TRIGGER AS $$
DECLARE
    registration_deadline   DATE;
    register_count          INTEGER;
    redeem_count            INTEGER;
    cancel_count            INTEGER;
BEGIN
    IF (TG_OP = 'UPDATE' AND NEW.customer_id = OLD.customer_id AND NEW.course_id = OLD.course_id) THEN
        RETURN NEW;
    END IF;

    SELECT c.offering_registration_deadline INTO registration_deadline
    FROM CourseOfferings c
    WHERE c.course_id = NEW.course_id AND c.offering_launch_date = NEW.offering_launch_date;

    IF CURRENT_DATE > registration_deadline THEN
        RAISE EXCEPTION 'Registration deadline for this session is over.';
    END IF;

    SELECT COUNT(*) INTO register_count FROM Registers WHERE NEW.customer_id = customer_id AND NEW.course_id = course_id;
    SELECT COUNT(*) INTO redeem_count FROM Redeems WHERE NEW.customer_id = customer_id AND NEW.course_id = course_id;
    SELECT COUNT(*) INTO cancel_count FROM Cancels WHERE NEW.customer_id = customer_id AND NEW.course_id = course_id;
    IF (register_count > cancel_count - redeem_count) THEN
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
