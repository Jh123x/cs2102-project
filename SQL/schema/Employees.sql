drop table if exists Employees cascade;

/* I used check constraints on text instead of enum just due to preference, no particular reason */

create table Employees (
    eid integer primary key,
    name text,
    address text,
    phone text,
    email text,
    join_date date,
    depart_date date,
    /* How else to enforce the covering + non-overlapping constraint of Employee ISA PartTimeEmployee/FullTimeEmployee? */
    /* Need to know the type of contract before generating pay slip */
    /* Not good, will think more about this. Please advise. */
    contract text check (text in ('part time', 'full time'))
);

create table PartTimeEmployees (
    eid references Employees on update cascade,
    hourly_rate numeric
);

create table FullTimeEmployees (
    eid references Employees on update cascade,
    /* How else to enforce the covering + non-overlapping constraint on the full-time ISA relationship */
    -- job text check (job in ('manager', 'administrator', 'instructor')),
    monthly_salary numeric
);

/* Consideration: Whether to have the following tables with just one column */
/* Yes because this is needed to enforce the full time requirement on the following jobs, and e.g. the Manages table must reference from the Managers table too */
/* There is some data-duplicating/redundancy but as of now I can't think of a better way. But it does provide good abstraction for the Manages and Handles tables. */
/* Any thoughts? */

create table Managers (
    eid references FullTimeEmployees on update cascade
)

create table Administrators (
    eid references FullTimeEmployees on update cascade
)

create table Instructors (
    eid references Employees on update cascade
);