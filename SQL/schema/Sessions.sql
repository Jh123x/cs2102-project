DROP TABLE IF EXISTS Sessions CASCADE;
CREATE TABLE Sessions (
    sid INTEGER UNIQUE NOT NULL,
    date DATE NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    course_id INTEGER NOT NULL,
    launch_date DATE NOT NULL,
    rid INTEGER REFERENCES Rooms,
    instructor_id INTEGER REFERENCES Instructors,
    unique(course_id, date),
    PRIMARY KEY(sid, course_id, launch_date),
    FOREIGN KEY(launch_date, course_id) REFERENCES CourseOfferings(launch_date, course_id) ON DELETE CASCADE,
    CHECK(end_time > start_time),
    -- Check if the session is conducted between 9am - 12pm to 2pm - 6pm and between
    CHECK((9 <= EXTRACT(HOUR FROM start_time) AND EXTRACT(HOUR FROM start_time) <= 12) OR (14 <= EXTRACT(HOUR FROM start_time) AND EXTRACT(HOUR FROM start_time) <= 18)),
    CHECK((9 <= EXTRACT(HOUR FROM end_time) AND EXTRACT(HOUR FROM end_time) <= 12) OR (14 <= EXTRACT(HOUR FROM end_time) AND EXTRACT(HOUR FROM end_time) <= 18))    
);
DROP TABLE IF EXISTS Cancels CASCADE;
CREATE TABLE Cancels (
    date TIMESTAMP PRIMARY KEY,
	refund_amt NUMERIC,
	package_credit INTEGER,
	sid INTEGER NOT NULL REFERENCES Sessions(sid),
    cust_id INTEGER NOT NULL REFERENCES Customers(cust_id)
);