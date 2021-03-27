drop table if exists PaySlips cascade;
create table PaySlips (
    eid integer references Employees ON DELETE CASCADE ON UPDATE CASCADE,
    payment_date date,
    amount numeric,
    num_work_hours integer default null,
    num_work_days integer default null,
    primary key (eid, payment_date),
    CHECK ((num_work_days is null and num_work_hours is not null) or (num_work_days is not null and num_work_hours is null)),
    CHECK (num_work_hours is null or num_work_hours >= 0),
    CHECK (num_work_days is null or num_work_days >= 0),
    CHECK (amount >= 0)
);