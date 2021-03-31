CREATE OR REPLACE PROCEDURE add_employee (
        name TEXT,
        address TEXT,
        phone TEXT,
        email TEXT,
        join_date DATE,
        category TEXT, -- Manager / Admin / Instructor
        type TEXT, -- Full Time / Part Time
        salary_amount DEC(64, 2), -- hourly_rate for part-time and monthly_salary for full-time
        course_area TEXT[]
    ) AS $$
DECLARE
    eid INTEGER;
	area TEXT;
BEGIN
    /* Insert the employee in */
    INSERT INTO Employees(name, address, phone, email, join_date) VALUES (name, address, phone, email, join_date);

    /* Get the new id that is generated */
    SELECT e.eid INTO eid FROM Employees WHERE e.name = name AND e.address = address AND e.phone = phone AND e.email = email AND e.join_date = join_date;

    -- Add into part-time / full time
    IF (type = 'part-time') THEN
        INSERT INTO PartTimeEmployees VALUES (eid, salary_amount);
    ELSIF (type = 'full-time') THEN
        INSERT INTO FullTimeEmployees VALUES (eid, salary_amount);
    ELSE
        RAISE EXCEPTION 'Type not found';
    END IF;

    -- Add into role specific table
    IF (category = 'Manager') THEN
        INSERT INTO Managers VALUES (eid);

        -- Add them to the specified course area
        FOR area IN (SELECT * FROM course_area)
        LOOP
            INSERT INTO Course_areas VALUES (area, eid);
        END LOOP;
    ELSIF (category = 'Admin') THEN
        INSERT INTO Administrators VALUES (eid);
        IF (course_area.COUNT > 0) THEN
            RAISE EXCEPTION 'Admin should not have course area';
		END IF;
    ELSIF (category = 'Instructor') THEN
        INSERT INTO Instructors VALUES (eid);
        FOR area IN (SELECT * FROM course_area)
        LOOP
            INSERT INTO Specializes VALUES (eid, area);
        END LOOP;
        IF (type = 'part-time') THEN
            INSERT INTO PartTimeInstructors VALUES (eid);
        ELSIF (type = 'full-time') THEN
            INSERT INTO FullTimeInstructors VALUES (eid);
        END IF;
    ELSE
        RAISE EXCEPTION 'Category not found';
    END IF;
END;
$$ LANGUAGE plpgsql;
