CREATE OR REPLACE FUNCTION add_employee (
    employee_name TEXT,
    employee_address TEXT,
    employee_phone TEXT,
    employee_email TEXT,
    employee_join_date DATE,
    category TEXT, /* Manager / Admin / Instructor */
    type TEXT, /* Full Time / Part Time */
    salary_amount DEC(64, 2), /* hourly_rate for part-time and monthly_salary for full-time */
    course_areas TEXT[] DEFAULT '{}'
)
RETURNS TABLE (employee_id INTEGER) AS $$
DECLARE
    new_employee RECORD;
    area TEXT;
BEGIN
    /* Insert the employee in */
    INSERT INTO Employees
        (employee_name, employee_address, employee_phone, employee_email, employee_join_date)
    VALUES
        (employee_name, employee_address, employee_phone, employee_email, employee_join_date)
    RETURNING * INTO new_employee;

    employee_id := new_employee.employee_id;

    /* Add into part-time / full time */
    IF (type ILIKE 'part-time') THEN
        INSERT INTO PartTimeEmployees (employee_id, hourly_rate) VALUES (employee_id, salary_amount);
    ELSIF (type ILIKE 'full-time') THEN
        INSERT INTO FullTimeEmployees (employee_id, monthly_salary) VALUES (employee_id, salary_amount);
    ELSE
        RAISE EXCEPTION 'Type not found';
    END IF;

    /* Add into role specific table */
    IF (category ILIKE 'Manager') THEN
        INSERT INTO Managers (manager_id) VALUES (employee_id);

        /* Add them to the specified course area */
        FOREACH course_area_name IN ARRAY course_areas
        LOOP
            INSERT INTO CourseAreas (course_area_name, manager_id) VALUES (course_area_name, employee_id);
        END LOOP;
    ELSIF (category ILIKE 'Admin') THEN
        INSERT INTO Administrators (admin_id) VALUES (employee_id);
        IF (course_areas.COUNT > 0) THEN
            RAISE EXCEPTION 'Admin should not have course area';
        END IF;
    ELSIF (category ILIKE 'Instructor') THEN
        INSERT INTO Instructors (instructor_id) VALUES (employee_id);

        IF (type ILIKE 'part-time') THEN
            INSERT INTO PartTimeInstructors (instructor_id) VALUES (employee_id);
        ELSIF (type ILIKE 'full-time') THEN
            INSERT INTO FullTimeInstructors (instructor_id) VALUES (employee_id);
        ELSE
            RAISE EXCEPTION 'Invalid type of instructor';
        END IF;

        FOREACH course_area_name IN ARRAY course_area
        LOOP
            INSERT INTO Specializes (instructor_id, course_area_name) VALUES (employee_id, course_area_name);
        END LOOP;
    ELSE
        RAISE EXCEPTION 'Category not found';
    END IF;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;
