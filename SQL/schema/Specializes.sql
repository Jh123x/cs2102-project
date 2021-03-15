drop table if exists Specializes cascade;
create table Specializes (
    instructor_id INTEGER,
    cArea_name TEXT,
    PRIMARY KEY(instructor_id, cArea_name),
    FOREIGN KEY(instructor_id) REFERENCES Instructors,
    FOREIGN KEY(cArea_name) REFERENCES Course_areas
);