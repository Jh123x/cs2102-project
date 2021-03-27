DROP TABLE IF EXISTS PaySlips cascade;
CREATE TABLE PaySlips (
    eid INTEGER,
    payment_date DATE,
    amount DEC(64,2),
    num_work_hours INTEGER DEFAULT NULL,
    num_work_days INTEGER DEFAULT NULL,

    PRIMARY KEY (eid, payment_date),
    FOREIGN KEY (eid) REFERENCES Employees ON DELETE CASCADE ON UPDATE CASCADE,

    CHECK ((num_work_days IS NULL AND num_work_hours IS NOT NULL) OR (num_work_days IS NOT NULL AND num_work_hours IS NULL)),
    CHECK (num_work_hours IS NULL OR num_work_hours >= 0),
    CHECK (num_work_days IS NULL OR num_work_days >= 0),
    CHECK (amount >= 0)
);