DROP TABLE IF EXISTS Employees CASCADE;

CREATE TABLE Employees (
    employee_id SERIAL PRIMARY KEY,
    employee_name TEXT,
    employee_address TEXT,
    employee_phone TEXT,
    employee_email TEXT,
    employee_join_date date,
    employee_depart_date date DEFAULT NULL,

    CHECK (employee_depart_date IS NULL OR (employee_depart_date > employee_join_date)),
    CHECK (employee_email ~ '.+@.+\..+'),
    CHECK (employee_phone ~ '^[0-9]+$')
);

DROP TABLE IF EXISTS PartTimeEmployees CASCADE;
CREATE TABLE PartTimeEmployees (
    employee_id INTEGER PRIMARY KEY,
    employee_hourly_rate DEC(64,2),
    CHECK (employee_hourly_rate >= 0),

    FOREIGN KEY (employee_id) REFERENCES Employees (employee_id) ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS FullTimeEmployees CASCADE;
CREATE TABLE FullTimeEmployees (
    employee_id INTEGER PRIMARY KEY,
    employee_monthly_salary DEC(64,2),

    FOREIGN KEY (employee_id) REFERENCES Employees (employee_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CHECK (employee_monthly_salary >= 0)
);

DROP TABLE IF EXISTS Managers CASCADE;
CREATE TABLE Managers (
    manager_id INTEGER PRIMARY KEY,
    FOREIGN KEY (manager_id) REFERENCES FullTimeEmployees (employee_id) ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS Administrators CASCADE;
CREATE TABLE Administrators (
    admin_id INTEGER PRIMARY KEY,
    FOREIGN KEY (admin_id) REFERENCES FullTimeEmployees (employee_id) ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS Instructors CASCADE;
CREATE TABLE Instructors (
    instructor_id INTEGER PRIMARY KEY,
    FOREIGN KEY (instructor_id) REFERENCES Employees (employee_id) ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS PartTimeInstructors CASCADE;
CREATE TABLE PartTimeInstructors (
    instructor_id INTEGER REFERENCES PartTimeEmployees (employee_id) REFERENCES Instructors (instructor_id) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (instructor_id)
);

DROP TABLE IF EXISTS FullTimeInstructors CASCADE;
CREATE TABLE FullTimeInstructors (
    instructor_id INTEGER REFERENCES FullTimeEmployees (employee_id) REFERENCES Instructors (instructor_id) ON UPDATE CASCADE ON DELETE CASCADE,
    PRIMARY KEY (instructor_id)
);

DROP TABLE IF EXISTS Customers CASCADE;
CREATE TABLE Customers (
    customer_id SERIAL PRIMARY KEY,
    customer_phone INTEGER NOT NULL,
    customer_address TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    customer_email TEXT NOT NULL,

    CHECK(customer_email ~ '.+@.+\..+'),
    CHECK(customer_phone > 0)
);

DROP TABLE IF EXISTS CreditCards CASCADE;
CREATE TABLE CreditCards (
    credit_card_number CHAR(16) PRIMARY KEY,
    credit_card_cvv CHAR(3) NOT NULL,
    credit_card_expiry_date DATE NOT NULL,

    CHECK (credit_card_number ~ '[0-9]{16}'),
    CHECK (credit_card_cvv ~ '[0-9]{3}')
);

DROP TABLE IF EXISTS Rooms CASCADE;
CREATE TABLE Rooms (
    room_id INTEGER PRIMARY KEY,
    room_location TEXT UNIQUE NOT NULL,
    room_seating_capacity INTEGER NOT NULL,

    CHECK(room_seating_capacity >= 0)
);
DROP TABLE IF EXISTS CourseAreas CASCADE;
CREATE TABLE CourseAreas (
    course_area_name TEXT PRIMARY KEY,
    manager_id INTEGER NOT NULL REFERENCES Managers (manager_id)
);

DROP TABLE IF EXISTS Courses CASCADE;
CREATE TABLE Courses (
    course_id SERIAL PRIMARY KEY,
    course_title TEXT UNIQUE NOT NULL,
    course_description TEXT NOT NULL,
    course_duration INTEGER NOT NULL,
    course_area_name TEXT NOT NULL REFERENCES CourseAreas,

    CHECK(course_duration >= 0)
);

DROP TABLE IF EXISTS CourseOfferings CASCADE;
CREATE TABLE CourseOfferings (
    offering_launch_date DATE NOT NULL, /* Courses have unique launch date */
    offering_fees DEC(64,2) NOT NULL,
    offering_registration_deadline DATE NOT NULL,
    offering_num_target_registration INTEGER NOT NULL,
    offering_seating_capacity INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    admin_id INTEGER NOT NULL,
    offering_start_date DATE NOT NULL,
    offering_end_date DATE NOT NULL,

    CHECK(offering_start_date <= offering_end_date),
    CHECK(offering_launch_date < offering_registration_deadline),
    CHECK(offering_seating_capacity >= offering_num_target_registration),
    CHECK(offering_num_target_registration >= 0),
    CHECK(offering_fees >= 0),
    CHECK(offering_start_date >= offering_registration_deadline + INTEGER '10'),

    PRIMARY KEY(offering_launch_date, course_id),
    FOREIGN KEY(course_id) REFERENCES Courses ON DELETE CASCADE,
    FOREIGN KEY(admin_id) REFERENCES Administrators ON UPDATE CASCADE
);

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
    CHECK((9 <= session_start_hour AND session_end_hour <= 12) OR (14 <= session_start_hour AND session_end_hour <= 18)),
    CHECK(session_end_hour > session_start_hour)
);

DROP TABLE IF EXISTS Cancels CASCADE;
CREATE TABLE Cancels (
    cancel_timestamp TIMESTAMP PRIMARY KEY,
    cancel_refund_amount DEC(64,2),
    cancel_package_credit INTEGER,
    course_id INTEGER NOT NULL,
    session_id INTEGER NOT NULL,
    offering_launch_date DATE NOT NULL,
    customer_id INTEGER NOT NULL REFERENCES Customers(customer_id),

    CHECK(cancel_refund_amount >= 0),
    FOREIGN KEY (course_id, session_id, offering_launch_date) REFERENCES Sessions(course_id, session_id, offering_launch_date) MATCH FULL
);

DROP TABLE IF EXISTS CoursePackages CASCADE;
CREATE TABLE CoursePackages (
    package_id SERIAL PRIMARY KEY,
    package_name TEXT NOT NULL,
    package_num_free_registrations INTEGER NOT NULL,
    package_sale_start_date DATE NOT NULL,
    package_sale_end_date DATE NOT NULL,
    package_price DEC(64,2) NOT NULL,

    CHECK(package_price >= 0),
    CHECK(package_num_free_registrations >= 0),
    CHECK(package_sale_start_date <= package_sale_end_date)
);

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

DROP TABLE IF EXISTS PaySlips CASCADE;
CREATE TABLE PaySlips (
    employee_id INTEGER,
    payslip_date DATE NOT NULL,
    payslip_amount DEC(64,2) NOT NULL,
    payslip_num_work_hours INTEGER DEFAULT NULL,
    payslip_num_work_days INTEGER DEFAULT NULL,

    /* either num_work_hours or num_work_days is null */
    CHECK ((payslip_num_work_days IS NULL) <> (payslip_num_work_hours IS NULL)),
    CHECK (payslip_num_work_hours IS NULL OR payslip_num_work_hours >= 0),
    CHECK (payslip_num_work_days IS NULL OR payslip_num_work_days >= 0),
    CHECK (payslip_amount >= 0),

    PRIMARY KEY (employee_id, payslip_date),
    FOREIGN KEY (employee_id) REFERENCES Employees ON DELETE CASCADE ON UPDATE CASCADE
);

DROP TABLE IF EXISTS Specializes CASCADE;
CREATE TABLE Specializes (
    instructor_id INTEGER REFERENCES Instructors (instructor_id),
    course_area_name TEXT REFERENCES CourseAreas (course_area_name),

    PRIMARY KEY(instructor_id, course_area_name)    
);

