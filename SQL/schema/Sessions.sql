DROP TABLE IF EXISTS Sessions CASCADE;
CREATE TABLE Sessions (
    session_id INTEGER NOT NULL,
    session_date DATE NOT NULL,
    session_start_hour INTEGER NOT NULL,
    session_end_hour INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    offering_launch_date DATE NOT NULL,
    room_id INTEGER REFERENCES Rooms,
    instructor_id INTEGER REFERENCES Instructors (instructor_id),

    UNIQUE(course_id, session_date, session_start_hour),
    PRIMARY KEY(session_id, course_id, offering_launch_date),
    FOREIGN KEY(course_id, offering_launch_date) REFERENCES CourseOfferings(course_id, offering_launch_date) ON DELETE CASCADE,

    /* Check if the session is conducted between 9am - 12pm to 2pm - 6pm and between */
    CHECK(to_char(session_date, 'Dy') IN ('Mon','Tue', 'Wed','Thu','Fri')),
    CHECK((9 <= session_start_hour AND session_start_hour < 12) OR (14 <= session_start_hour AND session_start_hour < 18)),
    CHECK((9 < session_end_hour AND session_end_hour <= 12) OR (14 < session_end_hour AND session_end_hour <= 18)),
    CHECK(session_end_hour > session_start_hour)
);

DROP TABLE IF EXISTS Cancels CASCADE;
CREATE TABLE Cancels (
    cancel_date TIMESTAMP PRIMARY KEY,
    cancel_refund_amt DEC(64,2),
    cancel_package_credit INTEGER,
    course_id INTEGER NOT NULL,
    session_id INTEGER NOT NULL,
    offering_launch_date DATE NOT NULL,
    customer_id INTEGER NOT NULL REFERENCES Customers(customer_id),

    CHECK(cancel_refund_amt >= 0),
    FOREIGN KEY (course_id, session_id, offering_launch_date) REFERENCES Sessions(course_id, session_id, offering_launch_date) MATCH FULL
);