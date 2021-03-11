drop table if exists Courses cascade;

create table Courses (
    course_id TEXT PRIMARY KEY,
    title TEXT UNIQUE,
    course_description TEXT,
    duration INTEGER,
    cArea_name TEXT NOT NULL REFERENCES Course_areas
);