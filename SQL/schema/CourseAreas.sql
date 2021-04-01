DROP TABLE IF EXISTS CourseAreas CASCADE;
CREATE TABLE CourseAreas (
    course_area_name TEXT PRIMARY KEY,
    manager_id INTEGER NOT NULL REFERENCES Managers (manager_id)
);
