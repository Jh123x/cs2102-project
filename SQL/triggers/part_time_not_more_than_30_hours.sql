CREATE OR REPLACE FUNCTION part_time_hour_check()
RETURNS TRIGGER AS $$
DECLARE
    hours INTEGER;
BEGIN
    SELECT COALESCE(SUM(session_end_hour - session_start_hour), 0) INTO hours
    FROM Sessions
    WHERE instructor_id = NEW.instructor_id AND DATE_TRUNC('month', session_date) = DATE_TRUNC('month', NEW.session_date);

    IF (hours > 30) THEN
        RAISE EXCEPTION 'Part time Employee working too much';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER not_more_than_30_trigger
AFTER INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION part_time_hour_check();
