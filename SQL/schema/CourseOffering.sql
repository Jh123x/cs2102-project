drop table if exists CourseOfferings cascade;
/*May consider changing datatype for fees to MONEY*/
/*Should handle be included here? Creating a sepearate table for Handles might not allow the admin to handle different course offering that falls on the same launch date..*/
create table CourseOfferings (
    launch_date DATE,
    fees NUMERIC,
    start_date DATE,
    end_date DATE,
    registration_deadline DATE,
    target_number_registration DATE,
    seating_capacity DATE,
    course_id INTEGER,
    admin_id INTEGER,
    PRIMARY KEY(launch_date, course_id, admin_id),
    FOREIGN KEY(course_id) REFERENCES Courses on delete cascade,
    FOREIGN KEY(admin_id) REFERENCES Administrators.eid on delete cascade
);