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
CREATE OR REPLACE FUNCTION remove_employee(
    r_employee_id INTEGER,
    departure_date DATE
) RETURNS VOID
AS $$
DECLARE
    isAdmin_count INTEGER;
    isManaging_count INTEGER;
    isTeaching_count INTEGER;
    isExists_count INTEGER;
BEGIN
    /* The below conditions needs changing; need to check if it's managing a course offering/session AFTER departure date */
    /* Check if they are still handling admin tasks */
    SELECT COUNT(*) INTO isAdmin_count FROM CourseOfferings c WHERE c.admin_id = r_employee_id;

    /* Check if they are still teaching some course */
    SELECT COUNT(*) INTO isManaging_count FROM CourseAreas c WHERE c.manager_id = r_employee_id;

    /* Check if they are manager managing some area */
    SELECT COUNT(*) INTO isTeaching_count FROM Sessions s WHERE s.instructor_id = r_employee_id;

    /*Check if the employee exists*/
    SELECT COUNT(*) into isExists_count FROM Employees e where e.employee_id = r_employee_id;

    IF (isAdmin_count > 0) THEN
        RAISE EXCEPTION 'Employee is still Admin for a CourseOffering';
    ELSIF (isManaging_count > 0) THEN
        RAISE EXCEPTION 'Employee is still managing a CourseArea';
    ELSIF (isTeaching_count > 0) THEN
        RAISE EXCEPTION 'Employee is still teaching a Session';
    ELSIF (isExists_count <= 0) THEN
        RAISE EXCEPTION 'Employee does not exist';
    END IF;

    /* Leave it to insert/update CHECK() to ensure departure_date is >= join_date*/
    UPDATE Employees e
    SET employee_depart_date = departure_date
    WHERE e.employee_id = r_employee_id;
END;
$$ LANGUAGE plpgsql;
