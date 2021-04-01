DROP TABLE IF EXISTS Courses CASCADE;
CREATE TABLE Courses (
    course_id SERIAL PRIMARY KEY,
    course_title TEXT UNIQUE NOT NULL,
    course_description TEXT NOT NULL,
    course_duration INTEGER NOT NULL,
    course_area_name TEXT NOT NULL REFERENCES CourseAreas,

    CHECK(course_duration >= 0)
);
