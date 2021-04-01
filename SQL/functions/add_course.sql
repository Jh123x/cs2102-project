CREATE OR REPLACE PROCEDURE add_course (
    course_title TEXT,
    course_description TEXT,
    course_area_name TEXT,
    course_duration INTEGER
) AS $$
BEGIN
    INSERT INTO Courses
    (course_title, course_description, course_duration, course_area_name)
    VALUES
    (course_title, course_description, course_duration, course_area_name);
END;
$$ LANGUAGE plpgsql;
