DROP TABLE IF EXISTS Specializes CASCADE;
CREATE TABLE Specializes (
    employee_id INTEGER,
    course_area_name TEXT,

    PRIMARY KEY(employee_id, course_area_name),
    FOREIGN KEY(employee_id) REFERENCES Instructors,
    FOREIGN KEY(course_area_name) REFERENCES CourseAreas
);
