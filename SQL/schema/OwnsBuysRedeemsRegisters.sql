DROP TABLE IF EXISTS Owns CASCADE;
CREATE TABLE Owns (
    customer_id INTEGER NOT NULL REFERENCES Customers,
    credit_card_number CHAR(16) NOT NULL REFERENCES CreditCards,
    own_from_timestamp TIMESTAMP NOT NULL,
    PRIMARY KEY(customer_id, credit_card_number)
);

DROP TABLE IF EXISTS Buys CASCADE;
CREATE TABLE Buys (
    buy_timestamp TIMESTAMP PRIMARY KEY NOT NULL,
    buy_num_remaining_redemptions INTEGER NOT NULL,
    package_id INTEGER NOT NULL REFERENCES CoursePackages,
    customer_id INTEGER NOT NULL,
    credit_card_number CHAR(16) NOT NULL,

    CHECK(buy_num_remaining_redemptions >= 0),
    FOREIGN KEY(customer_id, credit_card_number) REFERENCES Owns (customer_id, credit_card_number) MATCH FULL
);

DROP TABLE IF EXISTS Redeems CASCADE;
CREATE TABLE Redeems (
    redeem_timestamp TIMESTAMP PRIMARY KEY NOT NULL,
    buy_timestamp TIMESTAMP NOT NULL REFERENCES Buys,
    session_id INTEGER NOT NULL,
    offering_launch_date DATE NOT NULL,
    course_id INTEGER NOT NULL,
    redeem_cancelled BOOLEAN NOT NULL DEFAULT FALSE,

    FOREIGN KEY(session_id, offering_launch_date, course_id) REFERENCES Sessions(session_id, offering_launch_date, course_id) ON UPDATE CASCADE
);

DROP TABLE IF EXISTS Registers CASCADE;
CREATE TABLE Registers (
    register_timestamp TIMESTAMP NOT NULL,
    customer_id INTEGER NOT NULL,
    credit_card_number CHAR(16) NOT NULL,
    session_id INTEGER NOT NULL,
    offering_launch_date DATE NOT NULL,
    course_id INTEGER NOT NULL,
    register_cancelled BOOLEAN NOT NULL DEFAULT FALSE,

    PRIMARY KEY(register_timestamp),
    FOREIGN KEY(session_id, offering_launch_date, course_id) REFERENCES Sessions(session_id, offering_launch_date, course_id) ON UPDATE CASCADE,
    FOREIGN KEY(customer_id, credit_card_number) REFERENCES Owns (customer_id, credit_card_number)
);

DROP VIEW IF EXISTS Enrolment;
CREATE VIEW Enrolment AS
SELECT register_timestamp AS enroll_timestamp, session_id, course_id, offering_launch_date, customer_id, 'registers' AS table_name
FROM Registers
WHERE register_cancelled IS NOT TRUE
UNION
SELECT redeem_timestamp AS enroll_timestamp, session_id, course_id, offering_launch_date, customer_id, 'redeems' AS table_name
FROM Redeems NATURAL JOIN Buys
WHERE redeem_cancelled IS NOT TRUE;

DROP VIEW IF EXISTS EnrolmentCount;
CREATE VIEW EnrolmentCount AS
SELECT session_id, course_id, offering_launch_date, COUNT(*) AS num_enrolled
FROM Sessions NATURAL LEFT OUTER JOIN Enrolment
GROUP BY session_id, course_id, offering_launch_date;
