/*Check that the sessions inserted are not before the offering start date or after the offering end date*/

CREATE OR REPLACE FUNCTION session_date_check() RETURNS TRIGGER
AS $$
DECLARE
    start_date DATE;
    end_date DATE;
BEGIN
    SELECT c.offering_start_date, c.offering_end_date INTO start_date, end_date
    FROM CourseOfferings c
    WHERE c.course_id = NEW.course_id
    AND c.offering_launch_date = NEW.offering_launch_date;

    /*Data sql violates this check for some reason*/
    IF (NEW.session_date BETWEEN start_date AND end_date) THEN
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'Session cannot be outside offering start date and end date';
    END IF;

END;
$$ LANGUAGE plpgsql;



DROP TRIGGER IF EXISTS session_date_check_trigger ON Sessions;
CREATE TRIGGER session_date_check_trigger
AFTER INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION session_date_check();
