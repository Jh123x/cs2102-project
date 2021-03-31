DROP TABLE IF EXISTS Courses CASCADE;
CREATE TABLE Courses (
    course_id SERIAL PRIMARY KEY,
    title TEXT UNIQUE,
    course_description TEXT,
    duration INTEGER,
    course_area_name TEXT NOT NULL REFERENCES CourseAreas,

    CHECK(duration >= 0)
);
