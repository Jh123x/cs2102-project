/*
    2. remove_employee: This routine is used to update an employee's departed date a non-null value.
    The inputs to the routine is
        an employee identifier and
        a departure date.
    The update operation is rejected if any one of the following conditions hold:
        (1) the employee is an administrator who is handling some course offering where its registration deadline is after the employee's departure date;
        (2) the employee is an instructor who is teaching some course session that starts after the employee's departure date; or
        (3) the employee is a manager who is managing some area.
*/


DROP FUNCTION IF EXISTS is_active_admin CASCADE;
CREATE OR REPLACE FUNCTION is_active_admin (admin_id_arg INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(SELECT * FROM CourseOfferings co WHERE co.admin_id = admin_id_arg);
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS is_active_manager CASCADE;
CREATE OR REPLACE FUNCTION is_active_manager (manager_id_arg INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(SELECT * FROM CourseAreas ca WHERE ca.manager_id = manager_id_arg);
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS remove_employee;
CREATE OR REPLACE FUNCTION remove_employee (
    employee_id_arg INTEGER,
    employee_depart_date_arg DATE
) RETURNS VOID
AS $$
BEGIN
    /* The below conditions needs changing; need to check if it's managing a course offering/session AFTER departure date */
    IF employee_id_arg NOT IN (SELECT employee_id FROM Employees)
    THEN
        RAISE EXCEPTION 'Employee identifier % does not exist', employee_id_arg;
    /* Check if they are still handling admin tasks */
    ELSIF is_active_admin(employee_id_arg) IS TRUE
    THEN
        RAISE EXCEPTION 'Employee is still an administrator for a course offering.';
    /* Check if they are manager managing some area */
    ELSIF is_active_manager(employee_id_arg) IS TRUE
    THEN
        RAISE EXCEPTION 'Employee is still managing a course area.';
    /* Check if they are still teaching some course past employee's departure date */
    ELSIF EXISTS(SELECT * FROM Sessions s WHERE s.instructor_id = employee_id_arg AND s.session_date >= employee_depart_date_arg) THEN
        RAISE EXCEPTION 'Employee is still teaching a session after departure date.';
    END IF;

    /* Leave it to insert/update CHECK() to ensure employee_depart_date_arg is >= join_date */
    UPDATE Employees e
    SET employee_depart_date = employee_depart_date_arg
    WHERE e.employee_id = employee_id_arg;
END;
$$ LANGUAGE plpgsql;
