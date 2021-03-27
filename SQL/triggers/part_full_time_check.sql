CREATE OR REPLACE FUNCTION part_full_time_check() RETURNS TRIGGER AS $$
    DECLARE
        full_time_count INTEGER;
        part_time_count INTEGER;
    BEGIN
        SELECT COUNT(*) INTO full_time_count FROM FullTimeEmployees WHERE eid = NEW.eid;
        SELECT COUNT(*) INTO part_time_count FROM PartTimeEmployees WHERE eid = NEW.eid;
        IF (full_time_count + part_time_count > 0)
        THEN
            RAISE EXCEPTION 'Employee already exists in part time or full time role';
        END IF;
    END;
$$ LANGUAGE plpgsql;



CREATE TRIGGER part_time_insert_trigger
BEFORE INSERT OR UPDATE ON PartTimeEmployees
FOR EACH ROW EXECUTE FUNCTION part_full_time_check();

CREATE TRIGGER part_time_insert_trigger
BEFORE INSERT OR UPDATE ON FullTimeEmployees
FOR EACH ROW EXECUTE FUNCTION part_full_time_check();