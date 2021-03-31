DROP TABLE IF EXISTS Owns CASCADE;
CREATE TABLE Owns (
    customer_id INTEGER REFERENCES Customers,
    number CHAR(16) REFERENCES CreditCards,
    from_date DATE NOT NULL,
    PRIMARY KEY(customer_id, number)
);

DROP TABLE IF EXISTS Buys CASCADE;
CREATE TABLE Buys (
    date TIMESTAMP PRIMARY KEY,
    num_remaining_redemptions INTEGER NOT NULL,
    package_id INTEGER NOT NULL REFERENCES CoursePackages,
    customer_id INTEGER NOT NULL,
    number CHAR(16),

    CHECK(num_remaining_redemptions >= 0),
    FOREIGN KEY(customer_id, number) REFERENCES Owns (customer_id, number)
);

DROP TABLE IF EXISTS Redeems CASCADE;
CREATE TABLE Redeems (
    date TIMESTAMP PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    package_id INTEGER NOT NULL,
    session_id INTEGER,
    launch_date DATE,
    course_id INTEGER,

    FOREIGN KEY(session_id, launch_date, course_id) REFERENCES Sessions(session_id, launch_date, course_id)
);

DROP TABLE IF EXISTS Registers CASCADE;
CREATE TABLE Registers (
    date TIMESTAMP PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    number CHAR(16) NOT NULL,
    session_id INTEGER NOT NULL,
    launch_date DATE,
    course_id INTEGER,

    FOREIGN KEY(session_id, launch_date, course_id) REFERENCES Sessions(session_id, launch_date, course_id),
    FOREIGN KEY(customer_id, number) REFERENCES Owns (customer_id, number)
);
