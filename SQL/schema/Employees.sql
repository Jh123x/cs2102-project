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
    contract text check (contract in ('part time', 'full time'))
);

create table PartTimeEmployees (
    eid integer primary key,
    hourly_rate numeric,
    foreign key (eid) references Employees on update cascade
);

create table FullTimeEmployees (
    eid integer primary key,
    /* How else to enforce the covering + non-overlapping constraint on the full-time ISA relationship */
    -- job text check (job in ('manager', 'administrator', 'instructor')),
    monthly_salary numeric,
    foreign key (eid) references Employees on update cascade
);

/* Consideration: Whether to have the following tables with just one column */
/* Yes because this is needed to enforce the full time requirement on the following jobs, and e.g. the Manages table must reference from the Managers table too */
/* There is some data-duplicating/redundancy but as of now I can't think of a better way. But it does provide good abstraction for the Manages and Handles tables. */
/* Any thoughts? */

create table Managers (
    eid integer primary key,
    foreign key (eid) references FullTimeEmployees on update cascade
);

create table Administrators (
    eid integer primary key,
    foreign key (eid) references FullTimeEmployees on update cascade
);

create table Instructors (
    eid integer primary key,
    foreign key (eid) references Employees on update cascade
);

/*Added this part according to Tutorial 3*/

create table PartTimeInstructors (
    eid integer references PartTimeEmployees references Instructors on update cascade on delete cascade
);

create table FullTimeInstructors (
    eid integer references FullTimeEmployees references Instructors on update cascade
);