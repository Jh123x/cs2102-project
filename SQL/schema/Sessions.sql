CREATE TABLE IF NOT EXISTS Sessions(
    sid INTEGER PRIMARY KEY,
    date DATE NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    course_id INTEGER REFERENCES Offerings,
    unique(course_id, date)
);