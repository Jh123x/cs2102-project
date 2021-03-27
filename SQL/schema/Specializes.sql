drop table if exists Specializes cascade;
create table Specializes (
    instructor_id INTEGER,
    course_area_name TEXT,
    PRIMARY KEY(instructor_id, course_area_name),
    FOREIGN KEY(instructor_id) REFERENCES Instructors,
    FOREIGN KEY(course_area_name) REFERENCES CourseAreas
);