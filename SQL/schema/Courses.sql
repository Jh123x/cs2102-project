DROP TABLE IF EXISTS Courses cascade;
CREATE TABLE Courses (
    course_id INTEGER PRIMARY KEY,
    title TEXT UNIQUE,
    course_description TEXT,
    duration INTEGER,
    course_area_name TEXT NOT NULL REFERENCES CourseAreas,
    CHECK(duration >= 0)
);