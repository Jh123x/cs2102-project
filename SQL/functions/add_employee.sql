CREATE OR REPLACE PROCEDURE add_employee (
    name TEXT,
    address TEXT,
    phone TEXT,
    email TEXT,
    join_date DATE,
    category TEXT, /* Manager / Admin / Instructor */
    type TEXT, /* Full Time / Part Time */
    salary_amount DEC(64, 2), /* hourly_rate for part-time and monthly_salary for full-time */
    course_area TEXT[]
) AS $$
DECLARE
    employee_id INTEGER;
    area TEXT;
BEGIN
    /* Insert the employee in */
    INSERT INTO Employees
        (name, address, phone, email, join_date)
    VALUES
        (name, address, phone, email, join_date);

    /* Get the new id that is generated */
    SELECT e.employee_id INTO employee_id
    FROM Employees
    WHERE e.name = name
        AND e.address = address
        AND e.phone = phone
        AND e.email = email
        AND e.join_date = join_date;

    /* Add into part-time / full time */
    IF (type = 'part-time') THEN
        INSERT INTO PartTimeEmployees (employee_id, salary_amount) VALUES (employee_id, salary_amount);
    ELSIF (type = 'full-time') THEN
        INSERT INTO FullTimeEmployees (employee_id, salary_amount) VALUES (employee_id, salary_amount);
    ELSE
        RAISE EXCEPTION 'Type not found';
    END IF;

    /* Add into role specific table */
    IF (category = 'Manager') THEN
        INSERT INTO Managers (employee_id) VALUES (employee_id);

        /* Add them to the specified course area */
        FOREACH area IN ARRAY course_area
        LOOP
            INSERT INTO CourseAreas (area, employee_id) VALUES (area, employee_id);
        END LOOP;
    ELSIF (category = 'Admin') THEN
        INSERT INTO Administrators (employee_id) VALUES (employee_id);
        IF (course_area.COUNT > 0) THEN
            RAISE EXCEPTION 'Admin should not have course area';
        END IF;
    ELSIF (category = 'Instructor') THEN
        INSERT INTO Instructors (employee_id) VALUES (employee_id);

        IF (type = 'part-time') THEN
            INSERT INTO PartTimeInstructors (employee_id) VALUES (employee_id);
        ELSIF (type = 'full-time') THEN
            INSERT INTO FullTimeInstructors (employee_id) VALUES (employee_id);
        ELSE
            RAISE EXCEPTION 'Invalid type of instructor';
        END IF;

        FOREACH area IN ARRAY course_area
        LOOP
            INSERT INTO Specializes (employee_id, area) VALUES (employee_id, area);
        END LOOP;
    ELSE
        RAISE EXCEPTION 'Category not found';
    END IF;
END;
$$ LANGUAGE plpgsql;
