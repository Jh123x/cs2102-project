drop table if exists CourseOfferings cascade;
/*Should handle be included here? Creating a sepearate table for Handles might not allow the admin to handle different course offering that falls on the same launch date..*/
create table CourseOfferings (
    launch_date DATE,
    fees MONEY,
    start_date DATE,
    end_date DATE,
    registration_deadline DATE,
    target_number_registration INTEGER,
    seating_capacity INTEGER NOT NULL,
    course_id NOT NULL INTEGER,
    admin_id NOT NULL INTEGER,
    
    CHECK(start_date < end_date),
    CHECK(launch_date < registration_deadline),
    CHECK(seating_capacity >= target_number_registration),
    CHECK(target_number_registration >= 0),
    CHECK(fees >= 0),
    CHECK(DATEDIFF(day, registration_deadline, start_date) >= 10),

    PRIMARY KEY(launch_date, course_id),
    FOREIGN KEY(course_id) REFERENCES Courses on delete cascade,
    FOREIGN KEY(admin_id) REFERENCES Administrators on update cascade
);