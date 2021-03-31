-- Enforce non-overlap between admin, manager and instructors
CREATE OR REPLACE FUNCTION role_check()
RETURNS TRIGGER AS $$
DECLARE
    inst_count INTEGER;
    admin_count INTEGER;
    man_count INTEGER;
BEGIN

    /*If there is no change to the employee_id of the person during the update*/
    IF (TG_OP = 'UPDATE' AND NEW.employee_id = OLD.employee_id) THEN
        RETURN NEW;
    END IF;

    /*Get the number of employees with the same employee_id from the other tables*/
    SELECT COUNT(*) INTO inst_count FROM Instructors WHERE NEW.employee_id = employee_id;
    SELECT COUNT(*) INTO admin_count FROM Administrators WHERE NEW.employee_id = employee_id;
    SELECT COUNT(*) INTO man_count FROM Managers WHERE NEW.employee_id = employee_id;

    /*If the number is > 0 then the employee already exists in another role*/
    IF (inst_count + admin_count + man_count > 0) THEN
        RAISE EXCEPTION 'The Employee is already in another role.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER admin_check_trigger
BEFORE INSERT OR UPDATE ON Administrators
FOR EACH ROW EXECUTE FUNCTION role_check();

CREATE TRIGGER manager_check_trigger
BEFORE INSERT OR UPDATE ON Managers
FOR EACH ROW EXECUTE FUNCTION role_check();

CREATE TRIGGER instructor_check_trigger
BEFORE INSERT OR UPDATE ON Instructors
FOR EACH ROW EXECUTE FUNCTION role_check();
