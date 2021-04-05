CREATE OR REPLACE FUNCTION customer_cancels_check() RETURNS TRIGGER AS $$
DECLARE
    course_deadline DATE;
BEGIN
    /*Check if it is a package or not. Must be 1 or another and not both*/
    IF (NEW.cancel_refund_amt > 0 AND NEW.cancel_package_credit > 0) THEN
        RAISE EXCEPTION 'Either cancel_refund_amt or cancel_package_credit must be 0';
    END IF;

    IF (TG_OP = 'UPDATE' AND NEW.customer_id = OLD.customer_id) THEN
        return NEW;
    END IF;

    /*Get the date*/
    SELECT session_date INTO course_deadline FROM Sessions s
    WHERE s.course_id = NEW.course_id
    AND s.offering_launch_date = NEW.offering_launch_date
    AND s.session_id = NEW.session_id;


    IF (NEW.cancel_date >= course_deadline + INTEGER '7' AND (NEW.cancel_refund_amt > 0 OR NEW.cancel_package_credit > 0) ) THEN
        RAISE EXCEPTION 'Refunds closer than 7 days are not eligible for refund';
    END IF;

    IF (NOT EXISTS(
        SELECT 1 FROM Registers r
        WHERE r.customer_id = NEW.customer_id
        AND r.course_id = NEW.course_id
        AND r.offering_launch_date = NEW.offering_launch_date
    )) THEN 
        RAISE EXCEPTION 'Customer did not register for the course';
    END IF;

    return NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER customer_cancels_trigger
BEFORE INSERT OR UPDATE ON Cancels
FOR EACH ROW EXECUTE FUNCTION customer_cancels_check();
