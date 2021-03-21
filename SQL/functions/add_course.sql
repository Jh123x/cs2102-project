CREATE OR REPLACE PROCEDURE add_course (
        title TEXT,
        course_description TEXT,
        cArea_name TEXT,
        duration INTEGER
        
    ) AS $$
DECLARE
    curr_id INTEGER;
    SELECT MAX(course_id) + 1 INTO curr_id FROM Courses;
    INSERT INTO Courses
    VALUES (
            curr_id,
            title,
            course_description,
            duration,
            cArea_name
        );
$$ LANGUAGE SQL