/* Do not allow the removal of any employees */
CREATE OR REPLACE FUNCTION no_deletion_of_employees()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'No deleting of employees, use the function or set a depart date instead.';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER no_delete_employee_trigger
BEFORE DELETE ON Employees
FOR EACH ROW EXECUTE FUNCTION no_deletion_of_employees();
