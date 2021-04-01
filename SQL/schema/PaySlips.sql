DROP TABLE IF EXISTS PaySlips CASCADE;
CREATE TABLE PaySlips (
    employee_id INTEGER,
    payslip_date DATE NOT NULL,
    payslip_amount DEC(64,2) NOT NULL,
    payslip_num_work_hours INTEGER DEFAULT NULL,
    payslip_num_work_days INTEGER DEFAULT NULL,

    /* either num_work_hours or num_work_days is null */
    CHECK ((payslip_num_work_days IS NULL) <> (payslip_num_work_hours IS NULL)),
    CHECK (payslip_num_work_hours IS NULL OR payslip_num_work_hours >= 0),
    CHECK (payslip_num_work_days IS NULL OR payslip_num_work_days >= 0),
    CHECK (payslip_amount >= 0),

    PRIMARY KEY (employee_id, payslip_date),
    FOREIGN KEY (employee_id) REFERENCES Employees ON DELETE CASCADE ON UPDATE CASCADE
);
