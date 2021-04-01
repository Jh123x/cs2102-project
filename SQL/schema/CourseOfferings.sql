DROP TABLE IF EXISTS CourseOfferings CASCADE;
CREATE TABLE CourseOfferings (
    offering_launch_date DATE NOT NULL, /* Courses have unique launch date */
    offering_fees DEC(64,2) NOT NULL,
    offering_registration_deadline DATE NOT NULL,
    offering_num_target_registration INTEGER NOT NULL,
    offering_seating_capacity INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    admin_id INTEGER NOT NULL,

    /* Start and end date to be added to view */
    offering_start_date DATE NOT NULL,
    offering_end_date DATE NOT NULL,

    CHECK(offering_start_date < offering_end_date),
    CHECK(offering_launch_date < offering_registration_deadline),
    CHECK(offering_seating_capacity >= offering_num_target_registration),
    CHECK(offering_num_target_registration >= 0),
    CHECK(offering_fees >= 0),
    CHECK(offering_registration_deadline >= offering_start_date + INTEGER '10'),

    PRIMARY KEY(offering_launch_date, course_id),
    FOREIGN KEY(course_id) REFERENCES Courses ON DELETE CASCADE,
    FOREIGN KEY(admin_id) REFERENCES Administrators ON UPDATE CASCADE
);
