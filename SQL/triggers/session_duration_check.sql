CREATE OR REPLACE FUNCTION session_duration_check() RETURNS TRIGGER
AS $$
DECLARE
    session_duration INTEGER;
BEGIN
    /* Check if the old time and date = new time and date */
    IF (TG_OP = 'UPDATE' AND NEW.session_date = OLD.session_date AND NEW.session_start_hour = OLD.session_start_hour) THEN
        RETURN NEW;
    /* Check if it is a valid operation */
    ELSIF (TG_OP NOT IN ('INSERT', 'UPDATE')) THEN
        RAISE EXCEPTION 'Trigger is not suppose to be enforces in other methods.';
    END IF;

    /* Finding the duration from the course */
    SELECT c.course_duration INTO session_duration
    FROM Courses c
    WHERE c.course_id = NEW.course_id;

    /*Data sql violates this check for some reason*/
    IF (NEW.session_end_hour - NEW.session_start_hour = session_duration) THEN
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'Duration of session does not match course duration';
    END IF;

END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS session_duration_check_trigger ON Sessions;
CREATE TRIGGER session_duration_check_trigger
AFTER INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION session_duration_check();