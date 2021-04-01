DROP TABLE IF EXISTS Sessions CASCADE;
CREATE TABLE Sessions (
    session_id INTEGER NOT NULL,
    date DATE NOT NULL,
    start_time INTEGER NOT NULL,
    end_time INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    launch_date DATE NOT NULL,
    room_id INTEGER REFERENCES Rooms,
    employee_id INTEGER REFERENCES Instructors,

    UNIQUE(course_id, date),
    PRIMARY KEY(session_id, course_id, launch_date),
    FOREIGN KEY(course_id, launch_date) REFERENCES CourseOfferings(course_id, launch_date) ON DELETE CASCADE,

    /* Check if the session is conducted between 9am - 12pm to 2pm - 6pm and between */
    CHECK(to_char(date, 'Day') IN ('Monday','Tuesday', 'Wednesday','Thursday','Friday')),
    CHECK((9 <= start_time <= 12) OR (14 <= start_time <= 18)),
    CHECK((9 <= end_time <= 12) OR (14 <= end_time <= 18)),
    CHECK(end_time > start_time)
);

DROP TABLE IF EXISTS Cancels CASCADE;
CREATE TABLE Cancels (
    date TIMESTAMP PRIMARY KEY,
    refund_amt DEC(64,2),
    package_credit INTEGER,
    course_id INTEGER NOT NULL,
    session_id INTEGER NOT NULL,
    launch_date DATE NOT NULL,
    customer_id INTEGER NOT NULL REFERENCES Customers(customer_id),

    CHECK(refund_amt >= 0),
    FOREIGN KEY (course_id, session_id, launch_date) REFERENCES Sessions(course_id, session_id, launch_date) MATCH FULL
);
