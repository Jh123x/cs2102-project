DROP TABLE IF EXISTS CourseAreas CASCADE;
CREATE TABLE CourseAreas (
    name TEXT PRIMARY KEY,
    manager_id INTEGER NOT NULL REFERENCES Managers
);