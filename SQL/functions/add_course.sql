CREATE OR REPLACE PROCEDURE add_course (
        title TEXT,
        course_description TEXT,
        cArea_name TEXT,
        duration INTEGER
    ) AS $$
DECLARE
    curr_id INTEGER;
    area_count INTEGER;
BEGIN
    SELECT MAX(course_id) + 1 INTO curr_id FROM Courses;
    INSERT INTO Courses
    VALUES (
            curr_id,
            title,
            course_description,
            duration,
            cArea_name
        );

    SELECT count(*) INTO area_count FROM Course_areas WHERE name = cArea_name;
    IF area_count = 0 THEN
        INSERT INTO Course_areas (name, manager_id) VALUES (cArea_name, NULL);
    END IF;

END
$$ LANGUAGE plpgsql;