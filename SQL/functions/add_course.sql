CREATE OR REPLACE PROCEDURE add_course (
    title TEXT,
    course_description TEXT,
    course_area_name TEXT,
    duration INTEGER
) AS $$
DECLARE
    course_id INTEGER;
BEGIN
    SELECT MAX(course_id) + 1 INTO course_id FROM Courses;
    INSERT INTO Courses
        (course_id, title, course_description, duration, course_area_name)
    VALUES 
        (course_id, title, course_description, duration, course_area_name);
END;
$$ LANGUAGE plpgsql;
