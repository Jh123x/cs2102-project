/*
    25. pay_salary: This routine is used at the end of the month to pay salaries to employees.
    The routine inserts the new salary payment records and
        returns a table of records
        (sorted in ascending order of employee identifier)
        with the following information for each employee who is paid for the month:
            employee identifier,
            name,
            status (either part-time or full-time),
            number of work days for the month,
            number of work hours for the month,
            hourly rate,
            monthly salary, and
            salary amount paid.
    For a part-time employees, the values for number of work days for the month and monthly salary should be null.
    For a full-time employees, the values for number of work hours for the month and hourly rate should be null.
*/
DROP FUNCTION IF EXISTS pay_salary CASCADE;
CREATE OR REPLACE FUNCTION pay_salary()
RETURNS TABLE (employee_id INTEGER, name TEXT, status TEXT,
    num_work_days INTEGER, num_work_hours INTEGER,
    hourly_rate NUMERIC, monthly_salary NUMERIC, amount_paid NUMERIC)
AS $$
DECLARE
    curs_part_time CURSOR FOR (
        SELECT * FROM PartTimeEmployees NATURAL JOIN Employees
    );
    curs_full_time CURSOR FOR (
        SELECT * FROM FullTimeEmployees NATURAL JOIN Employees e
        WHERE e.employee_depart_date IS NULL OR e.employee_depart_date >= DATE_TRUNC('month', NOW())
    );
    r RECORD;

    first_work_day INTEGER;
    last_work_day INTEGER;
    num_days_in_month INTEGER;
BEGIN
    OPEN curs_part_time;
    LOOP
        FETCH curs_part_time INTO r;
        EXIT WHEN NOT FOUND;

        employee_id := r.employee_id;
        name := r.employee_name;
        status := 'part-time';
        num_work_days := NULL;

        SELECT COALESCE(SUM(session_end_hour - session_start_hour), 0) INTO num_work_hours
        FROM Sessions s
        WHERE r.employee_id = s.instructor_id AND DATE_TRUNC('month', s.session_date) = DATE_TRUNC('month', CURRENT_DATE);

        hourly_rate := r.employee_hourly_rate;
        monthly_salary := NULL;

        amount_paid := hourly_rate * num_work_hours;

        INSERT INTO PaySlips(employee_id, payslip_date, payslip_amount, payslip_num_work_hours, payslip_num_work_days)
        VALUES (employee_id, CURRENT_DATE, amount_paid, num_work_hours, num_work_days);
        RETURN NEXT;
    END LOOP;
    CLOSE curs_part_time;

    OPEN curs_full_time;
    LOOP
        FETCH curs_full_time INTO r;
        EXIT WHEN NOT FOUND;

        employee_id := r.employee_id;
        name := r.employee_name;
        status := 'full-time';
        num_work_hours := NULL;

        num_days_in_month := EXTRACT(days FROM DATE_TRUNC('month', NOW()) + interval '1 month - 1 day');
        IF r.employee_join_date < DATE_TRUNC('month', NOW()) THEN
            first_work_day := 1;
        ELSE
            first_work_day := EXTRACT(days FROM r.employee_join_date - DATE_TRUNC('month', NOW()));
        END IF;
        IF r.employee_depart_date IS NULL THEN
            last_work_day := num_days_in_month;
        ELSE
            last_work_day := EXTRACT(days FROM r.employee_join_date - DATE_TRUNC('month', NOW()));
        END IF;
        num_work_days := last_work_day - first_work_day + 1;

        hourly_rate := NULL;
        monthly_salary := r.employee_monthly_salary;

        amount_paid := monthly_salary * num_work_days / num_days_in_month;

        INSERT INTO PaySlips(employee_id, payslip_date, payslip_amount, payslip_num_work_hours, payslip_num_work_days)
        VALUES (employee_id, CURRENT_DATE, amount_paid, num_work_hours, num_work_days);
        RETURN NEXT;
    END LOOP;
    CLOSE curs_full_time;
END;
$$ LANGUAGE plpgsql;
