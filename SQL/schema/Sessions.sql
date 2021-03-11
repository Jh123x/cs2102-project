DROP TABLE IF EXISTS Sessions CASCADE;

CREATE TABLE Sessions (
    sid INTEGER PRIMARY KEY,
    date DATE NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    course_id INTEGER REFERENCES Offerings,
    unique(course_id, date)
);

CREATE TABLE Cancels (
    date TIMESTAMP PRIMARY KEY,
    sid INTEGER REFERENCES Sessions,
    cust_id INTEGER,
    number CHAR(16),
    FOREIGN KEY(cust_id, number) REFERENCES Owns (cust_id, number)
)