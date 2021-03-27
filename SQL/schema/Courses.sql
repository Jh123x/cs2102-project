DROP TABLE IF EXISTS Courses cascade;
CREATE TABLE Courses (
    course_id INTEGER PRIMARY KEY,
    title TEXT UNIQUE,
    course_description TEXT,
    duration INTEGER,
    cArea_name TEXT NOT NULL REFERENCES Course_areas,
    CHECK(duration >= 0)
);