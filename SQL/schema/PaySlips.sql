drop table if exists PaySlips cascade;
create table PaySlips (
    eid integer references Employees,
    payment_date date,
    amount numeric, -- Maybe Consider DEC(65,2) here?
    num_work_hours integer,
    num_work_days integer,
    primary key (eid, payment_date);
    -- Add constraint that num_work_hours and num_work_days > 0?
);