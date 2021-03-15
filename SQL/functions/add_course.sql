CREATE OR REPLACE PROCEDURE add_course (
        course_id TEXT,
        title TEXT,
        course_description TEXT,
        duration INTEGER,
        cArea_name TEXT
    ) AS $$
INSERT INTO Courses
VALUES (
        course_id,
        title,
        course_description,
        duration,
        cArea_name
    );
$$ LANGUAGE SQL