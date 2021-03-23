DROP TABLE if exists Employees CASCADE;
/* I used check constraints on TEXT instead of enum just due to preference, no particular reason */
CREATE TABLE Employees (
    eid INTEGER PRIMARY KEY,
    name TEXT,
    address TEXT,
    phone TEXT,
    email TEXT,
    join_date date,
    depart_date date,
    /* How else to enforce the covering + non-overlapping constraint of Employee ISA PartTimeEmployee/FullTimeEmployee? */
    /* Need to know the type of contract before generating pay slip */
    /* Not good, will think more about this. Please advise. */
    contract TEXT CHECK (contract IN ('part time', 'full time'))
    CHECK (depart_date > join_date),
    CHECK (email LIKE '%@%')
);
DROP TABLE IF EXISTS PartTimeEmployees;
CREATE TABLE PartTimeEmployees (
    eid INTEGER PRIMARY KEY,
    hourly_rate NUMERIC,
    CHECK (hourly_rate >= 0),
    FOREIGN KEY (eid) REFERENCES Employees ON UPDATE CASCADE
);
DROP TABLE IF EXISTS FullTimeEmployees;
CREATE TABLE FullTimeEmployees (
    eid INTEGER PRIMARY KEY,
    /* How else to enforce the covering + non-overlapping constraint on the full-time ISA relationship */
    -- job TEXT check (job in ('manager', 'administrator', 'instructor')),
    monthly_salary NUMERIC, -- Value in Cents
    CHECK (monthly_salary >= 0),
    FOREIGN KEY (eid) REFERENCES Employees ON UPDATE CASCADE
);
/* Consideration: Whether to have the following TABLEs with just one column */
/* Yes because this is needed to enforce the full time requirement on the following jobs, and e.g. the Manages TABLE must reference from the Managers TABLE too */
/* There is some data-duplicating/redundancy but as of now I can't think of a better way. But it does provide good abstraction for the Manages and Handles TABLEs. */
/* Any thoughts? */
DROP TABLE IF EXISTS Managers;
CREATE TABLE Managers (
    eid INTEGER PRIMARY KEY,
    FOREIGN KEY (eid) REFERENCES FullTimeEmployees ON UPDATE CASCADE
);
DROP TABLE IF EXISTS Administrators;
CREATE TABLE Administrators (
    eid INTEGER PRIMARY KEY,
    FOREIGN KEY (eid) REFERENCES FullTimeEmployees ON UPDATE CASCADE
);
DROP TABLE IF EXISTS Instructors;
CREATE TABLE Instructors (
    eid INTEGER PRIMARY KEY,
    FOREIGN KEY (eid) REFERENCES Employees ON UPDATE CASCADE
);
/*Added this part according to Tutorial 3*/
DROP TABLE IF EXISTS PartTimeInstructors;
CREATE TABLE PartTimeInstructors (
    eid INTEGER REFERENCES PartTimeEmployees REFERENCES Instructors ON UPDATE CASCADE ON DELETE CASCADE
);
DROP TABLE IF EXISTS FullTimeInstructors;
CREATE TABLE FullTimeInstructors (
    eid INTEGER REFERENCES FullTimeEmployees REFERENCES Instructors ON UPDATE CASCADE
);