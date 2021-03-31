DROP TABLE IF EXISTS PaySlips cascade;
CREATE TABLE PaySlips (
    employee_id INTEGER,
    payment_date DATE,
    amount DEC(64,2),
    num_work_hours INTEGER DEFAULT NULL,
    num_work_days INTEGER DEFAULT NULL,

    /* either num_work_hours or num_work_days is null */
    CHECK ((num_work_days IS NULL) <> (num_work_hours IS NULL)),
    CHECK (num_work_hours IS NULL OR num_work_hours >= 0),
    CHECK (num_work_days IS NULL OR num_work_days >= 0),
    CHECK (amount >= 0),

    PRIMARY KEY (employee_id, payment_date),
    FOREIGN KEY (employee_id) REFERENCES Employees ON DELETE CASCADE ON UPDATE CASCADE
);
