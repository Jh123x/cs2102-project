DROP FUNCTION IF EXISTS add_employee CASCADE;
CREATE OR REPLACE FUNCTION add_employee (
    employee_name TEXT,
    employee_address TEXT,
    employee_phone TEXT,
    employee_email TEXT,
    employee_join_date DATE,
    employee_category TEXT, /* Manager / Admin / Instructor */
    employee_type TEXT, /* Full Time / Part Time */
    salary_amount DEC(64, 2), /* hourly_rate for part-time and monthly_salary for full-time */
    course_area_names TEXT[] DEFAULT '{}'
)
RETURNS TABLE (employee_id INTEGER) AS $$
DECLARE
    new_employee RECORD;
    course_area_name TEXT;
BEGIN
    /* Insert the employee in */
    INSERT INTO Employees
    (employee_name, employee_address, employee_phone, employee_email, employee_join_date)
    VALUES
    (employee_name, employee_address, employee_phone, employee_email, employee_join_date)
    RETURNING * INTO new_employee;

    employee_id := new_employee.employee_id;

    /* Add into part-time / full time */
    IF (employee_type ILIKE 'part-time') THEN
        INSERT INTO PartTimeEmployees (employee_id, employee_hourly_rate) VALUES (employee_id, salary_amount);
    ELSIF (employee_type ILIKE 'full-time') THEN
        INSERT INTO FullTimeEmployees (employee_id, employee_monthly_salary) VALUES (employee_id, salary_amount);
    ELSE
        RAISE EXCEPTION 'Employee Type must be either Full-Time/Part-Time.';
    END IF;

    /* Add into role specific table */
    IF (employee_category ILIKE 'Manager') THEN
        IF (employee_type NOT ILIKE 'full-time') THEN
            RAISE EXCEPTION 'Employee type for Manager must be Full-time.';
        END IF;

        INSERT INTO Managers (manager_id) VALUES (employee_id);

        /* Add them to the specified course area */
        FOREACH course_area_name IN ARRAY course_area_names
        LOOP
            INSERT INTO CourseAreas (course_area_name, manager_id) VALUES (course_area_name, employee_id);
        END LOOP;
    ELSIF (employee_category ILIKE 'Admin') THEN
        IF (employee_type NOT ILIKE 'full-time') THEN
            RAISE EXCEPTION 'Employee type for Administrator must be Full-time.';
        END IF;

        INSERT INTO Administrators (admin_id) VALUES (employee_id);

        IF (course_area_names.COUNT > 0) THEN
            RAISE EXCEPTION 'Admin should not have course area';
        END IF;
    ELSIF (employee_category ILIKE 'Instructor') THEN
        INSERT INTO Instructors (instructor_id) VALUES (employee_id);

        IF (type ILIKE 'part-time') THEN
            INSERT INTO PartTimeInstructors (instructor_id) VALUES (employee_id);
        ELSE
            INSERT INTO FullTimeInstructors (instructor_id) VALUES (employee_id);
        END IF;

        FOREACH course_area_name IN ARRAY course_area_names
        LOOP
            INSERT INTO Specializes (instructor_id, course_area_name) VALUES (employee_id, course_area_name);
        END LOOP;
    ELSE
        RAISE EXCEPTION 'Employee category must be either Manager/Administrator/Instructor.';
    END IF;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;
