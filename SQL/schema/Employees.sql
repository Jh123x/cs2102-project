DROP TABLE if exists Employees CASCADE;

CREATE TABLE Employees (
    eid INTEGER PRIMARY KEY,
    name TEXT,
    address TEXT,
    phone TEXT,
    email TEXT,
    join_date date,
    depart_date date,

    CHECK (depart_date > join_date),
    CHECK (email LIKE '%@%.%')
);

DROP TABLE IF EXISTS PartTimeEmployees;
CREATE TABLE PartTimeEmployees (
    eid INTEGER PRIMARY KEY,
    hourly_rate MONEY,
    CHECK (hourly_rate >= 0),

    FOREIGN KEY (eid) REFERENCES Employees ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS FullTimeEmployees;
CREATE TABLE FullTimeEmployees (
    eid INTEGER PRIMARY KEY,
    monthly_salary MONEY,

    FOREIGN KEY (eid) REFERENCES Employees ON UPDATE CASCADE ON DELETE CASCADE,
    CHECK (monthly_salary >= 0)
);

DROP TABLE IF EXISTS Managers;
CREATE TABLE Managers (
    eid INTEGER PRIMARY KEY,
    FOREIGN KEY (eid) REFERENCES FullTimeEmployees ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS Administrators;
CREATE TABLE Administrators (
    eid INTEGER PRIMARY KEY,
    FOREIGN KEY (eid) REFERENCES FullTimeEmployees ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS Instructors;
CREATE TABLE Instructors (
    eid INTEGER PRIMARY KEY,
    FOREIGN KEY (eid) REFERENCES Employees ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS PartTimeInstructors;
CREATE TABLE PartTimeInstructors (
    eid INTEGER REFERENCES PartTimeEmployees REFERENCES Instructors ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS FullTimeInstructors;
CREATE TABLE FullTimeInstructors (
    eid INTEGER REFERENCES FullTimeEmployees REFERENCES Instructors ON UPDATE CASCADE ON DELETE CASCADE
);