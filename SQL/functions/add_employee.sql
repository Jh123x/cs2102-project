CREATE OR REPLACE PROCEDURE add_employee (
        name TEXT,
        address TEXT,
        phone TEXT,
        email TEXT,
        join_date date,
        category TEXT, -- Manager / Admin / Instructor
        type TEXT, -- Full Time / Part Time
        salary_amount numeric, -- hourly_rate for part-time and monthly_salary for full-time
        course_area TEXT[]
    ) AS $$
DECLARE
    eid INTEGER;
    area_count INTEGER;
BEGIN
    -- Generate the next eid
    SELECT MAX(e.eid) + 1 INTO eid FROM Employees;
    INSERT INTO Employees
    VALUES (
            eid,
            name,
            address,
            phone,
            email,
            join_date,
            NULL -- No depart date yet
        );

    -- Add into part-time / full time
    IF (type = 'part-time') THEN
        INSERT INTO PartTimeEmployees VALUES (eid, salary_amount);
    ELSE IF (type = 'full-time') THEN
        INSERT INTO FullTimeEmployees VALUES (eid, salary_amount);
    ELSE
        RAISE EXCEPTION "Type not found";
    ENDIF;

    -- Add into role specific table
    IF (category = "Manager") THEN
        INSERT INTO Managers VALUES (eid);

        -- Add them to the specified course area
        FOR area IN course_area
        LOOP
            SELECT count(*) INTO area_count FROM Course_areas WHERE name = area;
            IF area_count = 0 THEN
                INSERT INTO Course_areas VALUES (area, eid);
            ELSE
                UPDATE Course_areas SET manager_id = eid WHERE name = area;
            END IF;
        END LOOP;
    ELSE IF (category = "Admin") THEN
        INSERT INTO Administrators VALUES (eid);
        IF (course_area.COUNT > 0) THEN
            RAISE EXCEPTION "Admin should not have course area";
    ELSE IF (category = "Instructor") THEN
        INSERT INTO Instructors VALUES (eid);
        FOR area IN course_area
        LOOP
            INSERT INTO Specializes VALUES (eid, area);
        END LOOP;
        IF (type = "part-time") THEN
            INSERT INTO PartTimeInstructors VALUES (eid);
        ELSE IF (type = 'full-time') THEN
            INSERT INTO FullTimeInstructors VALUES (eid);
        ENDIF;
    ELSE
        RAISE EXCEPTION "Category not found";
    ENDIF;



END
$$ LANGUAGE plpgsql;