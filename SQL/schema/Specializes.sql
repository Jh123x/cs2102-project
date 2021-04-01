DROP TABLE IF EXISTS Specializes CASCADE;
CREATE TABLE Specializes (
    instructor_id INTEGER REFERENCES Instructors (instructor_id),
    course_area_name TEXT REFERENCES CourseAreas (course_area_name),

    PRIMARY KEY(instructor_id, course_area_name)    
);
