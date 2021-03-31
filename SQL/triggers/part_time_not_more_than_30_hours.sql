CREATE OR REPLACE FUNCTION part_time_hour_check()
RETURNS TRIGGER AS $$
DECLARE
    hours INTEGER;
BEGIN
    SELECT SUM(EXTRACT(epoch from (end_time - start_time)) / 3600.00) INTO hours
    FROM Sessions
    WHERE instructor_id = NEW.instructor_id;

    IF (hours > 30) THEN 
        RAISE EXCEPTION 'Part time Employee working too much';
    END IF;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER not_more_than_30_trigger
BEFORE INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION part_time_hour_check();
