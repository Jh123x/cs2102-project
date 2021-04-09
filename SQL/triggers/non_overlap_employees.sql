/* Enforce non-overlap between admin, manager and instructors */
DROP FUNCTION IF EXISTS role_check CASCADE;
CREATE OR REPLACE FUNCTION role_check()
RETURNS TRIGGER AS $$
DECLARE
    new_employee_id INTEGER;
BEGIN
    IF EXISTS(
        SELECT employee_id FROM (
            SELECT instructor_id AS employee_id FROM Instructors
            UNION ALL
            SELECT admin_id AS employee_id FROM Administrators
            UNION ALL
            SELECT manager_id AS employee_id FROM Managers
        ) AS Employees
        GROUP BY employee_id
        HAVING COUNT(employee_id) > 1
    )
    THEN
        RAISE EXCEPTION 'There are employees with multiple roles after operation.';
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS admin_check_trigger ON Administrators;
CREATE CONSTRAINT TRIGGER admin_check_trigger
AFTER INSERT OR UPDATE ON Administrators
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION role_check();

DROP TRIGGER IF EXISTS manager_check_trigger ON Managers;
CREATE CONSTRAINT TRIGGER manager_check_trigger
AFTER INSERT OR UPDATE ON Managers
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION role_check();

DROP TRIGGER IF EXISTS instructor_check_trigger ON Instructors;
CREATE CONSTRAINT TRIGGER instructor_check_trigger
AFTER INSERT OR UPDATE ON Instructors
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION role_check();
