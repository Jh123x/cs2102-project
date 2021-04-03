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
