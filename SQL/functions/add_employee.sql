CREATE OR REPLACE PROCEDURE add_employee (
        eid INTEGER PRIMARY KEY,
        name TEXT,
        address TEXT,
        phone TEXT,
        email TEXT,
        join_date date,
        category TEXT, -- Manager / Admin / Instructor
        type TEXT, -- Full Time / Part Time
        salary_amount numeric -- hourly_rate for part-time and monthly_salary for full-time
    ) AS $$
BEGIN
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
    ELSE IF (category = "Admin") THEN
        INSERT INTO Administrators VALUES (eid);
    ELSE IF (category = "Part-time-Instructor") THEN
        INSERT INTO PartTimeInstructors VALUES (eid);
    ELSE IF (category = "Full-time-Instructor") THEN
        INSERT INTO FullTimeInstructors VALUES (eid);
    ELSE
        RAISE EXCEPTION "Category not found";
    ENDIF;
END
$$ LANGUAGE plpgsql;