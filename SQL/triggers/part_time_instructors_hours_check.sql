-- Check that the working hours for part time instructors doesnt exceed 30 hours
CREATE OR REPLACE FUNCTION part_time_instructors_hours_check() RETURNS TRIGGER AS $$
    DECLARE

    BEGIN

    END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER pt_check_hours_trigger
BEFORE INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION part_time_instructors_hours_check();