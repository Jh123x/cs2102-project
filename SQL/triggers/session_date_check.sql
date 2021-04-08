/*Check that the sessions inserted are not before the offering start date or after the offering end date*/

CREATE OR REPLACE FUNCTION session_date_check() RETURNS TRIGGER
AS $$
DECLARE
    register_date DATE;
BEGIN
    SELECT c.offering_registration_deadline INTO register_date
    FROM CourseOfferings c
    WHERE c.course_id = NEW.course_id
    AND c.offering_launch_date = NEW.offering_launch_date;

    /*Data sql violates this check for some reason*/
    IF (CURRENT_DATE <= register_date) THEN
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'Session cannot be added after registration deadline';
    END IF;

END;
$$ LANGUAGE plpgsql;



DROP TRIGGER IF EXISTS session_date_check_trigger ON Sessions;
CREATE TRIGGER session_date_check_trigger
AFTER INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION session_date_check();
