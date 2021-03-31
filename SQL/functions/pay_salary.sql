CREATE OR REPLACE FUNCTION pay_salary()
RETURN TABLE (employee_id INTEGER, name TEXT, status TEXT,
    num_work_days INTEGER, num_work_hours INTEGER,
    hourly_rate NUMERIC, monthly_salary NUMERIC, amount NUMERIC)
AS $$
DECLARE

BEGIN

END;
$$ LANGUAGE plpgsql;
