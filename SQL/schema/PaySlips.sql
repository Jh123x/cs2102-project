drop table if exists PaySlips cascade;
create table PaySlips (
    eid integer references Employees ON DELETE CASCADE ON UPDATE CASCADE,
    payment_date date,
    amount numeric,
    num_work_hours integer,
    num_work_days integer,
    primary key (eid, payment_date),
    CHECK (num_work_hours >= 0),
    CHECK (num_work_days >= 0),
    CHECK (amount >= 0)
);