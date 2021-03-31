DROP TABLE if exists Employees CASCADE;

CREATE TABLE Employees (
    employee_id SERIAL PRIMARY KEY,
    name TEXT,
    address TEXT,
    phone TEXT,
    email TEXT,
    join_date date,
    depart_date date DEFAULT NULL,

    CHECK (depart_date > join_date),
    CHECK(email ~ '.+@.+\..+')
);

DROP TABLE IF EXISTS PartTimeEmployees;
CREATE TABLE PartTimeEmployees (
    employee_id INTEGER PRIMARY KEY,
    hourly_rate DEC(64,2),
    CHECK (hourly_rate >= 0),

    FOREIGN KEY (employee_id) REFERENCES Employees ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS FullTimeEmployees;
CREATE TABLE FullTimeEmployees (
    employee_id INTEGER PRIMARY KEY,
    monthly_salary DEC(64,2),

    FOREIGN KEY (employee_id) REFERENCES Employees ON UPDATE CASCADE ON DELETE CASCADE,
    CHECK (monthly_salary >= 0)
);

DROP TABLE IF EXISTS Managers;
CREATE TABLE Managers (
    employee_id INTEGER PRIMARY KEY,
    FOREIGN KEY (employee_id) REFERENCES FullTimeEmployees ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS Administrators;
CREATE TABLE Administrators (
    employee_id INTEGER PRIMARY KEY,
    FOREIGN KEY (employee_id) REFERENCES FullTimeEmployees ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS Instructors;
CREATE TABLE Instructors (
    employee_id INTEGER PRIMARY KEY,
    FOREIGN KEY (employee_id) REFERENCES Employees ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS PartTimeInstructors;
CREATE TABLE PartTimeInstructors (
    employee_id INTEGER REFERENCES PartTimeEmployees REFERENCES Instructors ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS FullTimeInstructors;
CREATE TABLE FullTimeInstructors (
    employee_id INTEGER REFERENCES FullTimeEmployees REFERENCES Instructors ON UPDATE CASCADE ON DELETE CASCADE
);
