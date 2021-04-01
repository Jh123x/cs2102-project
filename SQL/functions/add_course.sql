CREATE OR REPLACE PROCEDURE add_course (
    title TEXT,
    course_description TEXT,
    course_area_name TEXT,
    duration INTEGER
) AS $$
BEGIN
    INSERT INTO Courses
        (title, course_description, duration, course_area_name)
    VALUES
        (title, course_description, duration, course_area_name);
END;
$$ LANGUAGE plpgsql;
