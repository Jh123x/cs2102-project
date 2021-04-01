CREATE OR REPLACE FUNCTION part_full_time_check()
RETURNS TRIGGER AS $$
BEGIN
    IF (
        (NEW.employee_id IN (SELECT employee_id FROM PartTimeEmployees)) AND 
        (NEW.employee_id IN (SELECT employee_id FROM FullTimeEmployees))
    )
    THEN
        RAISE EXCEPTION 'Employee already exists in part time or full time role';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS part_time_insert_trigger ON PartTimeEmployees;
DROP TRIGGER IF EXISTS full_time_insert_trigger ON FullTimeEmployees;

CREATE TRIGGER part_time_insert_trigger
AFTER INSERT OR UPDATE ON PartTimeEmployees
FOR EACH ROW EXECUTE FUNCTION part_full_time_check();

CREATE TRIGGER full_time_insert_trigger
AFTER INSERT OR UPDATE ON FullTimeEmployees
FOR EACH ROW EXECUTE FUNCTION part_full_time_check();
