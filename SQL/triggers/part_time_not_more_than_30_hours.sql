CREATE OR REPLACE FUNCTION part_time_hour_check()
RETURNS TRIGGER AS $$
DECLARE
    hours INTEGER;
BEGIN
    SELECT SUM(end_time - start_time) INTO hours
    FROM Sessions
    WHERE instructor_id = NEW.instructor_id;

    IF (hours > 30) THEN
        RAISE EXCEPTION 'Part time Employee working too much';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER not_more_than_30_trigger
BEFORE INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION part_time_hour_check();
