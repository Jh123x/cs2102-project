drop table if exists CourseOfferings cascade;
create table CourseOfferings (
    id SERIAL UNIQUE NOT NULL,
    launch_date DATE,
    fees DEC(64,2),
    registration_deadline DATE,
    target_number_registration INTEGER,
    seating_capacity INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    admin_id INTEGER NOT NULL,

    /*Start and end date to be added to view*/
    start_date DATE,
    end_date DATE,
    
    CHECK(start_date < end_date),
    CHECK(launch_date < registration_deadline),
    CHECK(seating_capacity >= target_number_registration),
    CHECK(target_number_registration >= 0),
    CHECK(fees >= 0),
    CHECK(start_date >= registration_deadline + INTEGER '10'),

    PRIMARY KEY(launch_date, course_id),
    FOREIGN KEY(course_id) REFERENCES Courses on delete cascade,
    FOREIGN KEY(admin_id) REFERENCES Administrators on update cascade
);