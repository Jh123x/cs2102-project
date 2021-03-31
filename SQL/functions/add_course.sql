CREATE OR REPLACE PROCEDURE add_course (
        title TEXT,
        course_description TEXT,
        course_area_name TEXT,
        duration INTEGER
    ) AS $$
DECLARE
    curr_id INTEGER;
BEGIN
    SELECT MAX(course_id) + 1 INTO curr_id FROM Courses;
    INSERT INTO Courses
    VALUES (
            curr_id,
            title,
            course_description,
            duration,
            course_area_name
        );
END;
$$ LANGUAGE plpgsql;
