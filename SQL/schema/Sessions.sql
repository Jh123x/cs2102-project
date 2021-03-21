DROP TABLE IF EXISTS Sessions CASCADE;
CREATE TABLE Sessions (
    sid INTEGER PRIMARY KEY,
    date DATE NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    course_id INTEGER NOT NULL REFERENCES Offerings,
    rid INTEGER REFERENCES Rooms,
    instructor_id INTEGER REFERENCES Instructors,
    unique(course_id, date),
    CHECK(end_time > start_time),
    -- Check if the session is conducted between 9am - 12pm to 2pm - 6pm and between
    CHECK(9 <= EXTRACT(HOUR FROM start_time) <= 12 OR 14 <= EXTRACT(HOUR FROM start_time) <= 18),
    CHECK(9 <= EXTRACT(HOUR FROM end_time) 12 OR 14 <= EXTRACT(HOUR FROM end_time) <= 18)
    
);
CREATE TABLE Cancels (
    date TIMESTAMP PRIMARY KEY,
    sid INTEGER REFERENCES Sessions,
    cust_id INTEGER,
    number CHAR(16),
    FOREIGN KEY(cust_id, number) REFERENCES Owns (cust_id, number)
);