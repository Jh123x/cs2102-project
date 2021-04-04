CREATE OR REPLACE PROCEDURE remove_employee(
    r_employee_id INTEGER,
    departure_date DATE
) AS $$
DECLARE
    isAdmin_count INTEGER;
    isManaging_count INTEGER;
    isTeaching_count INTEGER;
BEGIN
    /* The below conditions needs changing; need to check if it's managing a course offering/session AFTER departure date */
    /* Check if they are still handling admin tasks */
    SELECT COUNT(*) INTO isAdmin_count FROM CourseOfferings c WHERE c.admin_id = r_employee_id;

    /* Check if they are still teaching some course */
    SELECT COUNT(*) INTO isManaging_count FROM CourseAreas c WHERE c.manager_id = r_employee_id;

    /* Check if they are manager managing some area */
    SELECT COUNT(*) INTO isTeaching_count FROM Sessions s WHERE s.instructor_id = r_employee_id;

    IF (isAdmin_count + isManaging_count + isTeaching_count > 0) THEN
        RAISE EXCEPTION 'Employee is still Admin/Managing/Teaching';
    END IF;

    /* Leave it to insert/update CHECK() to ensure departure_date is >= join_date*/
    UPDATE Employees e
    SET employee_depart_date = departure_date
    WHERE e.employee_id = r_employee_id;
END;
$$ LANGUAGE plpgsql;
