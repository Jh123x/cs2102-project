drop table if exists PaySlips cascade;

create table PaySlips (
    eid integer references Employees,
    payment_date date,
    amount numeric,
    num_work_hours integer,
    num_work_days integer,
    primary key (eid, payment_date);
);