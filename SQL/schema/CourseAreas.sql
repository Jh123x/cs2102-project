DROP TABLE IF EXISTS CourseAreas CASCADE;
CREATE TABLE CourseAreas (
    course_area_name TEXT PRIMARY KEY,
    course_area_manager_id INTEGER NOT NULL REFERENCES Managers (employee_id)
);
