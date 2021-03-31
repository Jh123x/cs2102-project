CREATE OR REPLACE FUNCTION find_instructors(course_id INTEGER, session_date DATE, session_start_hour TIMESTAMP)
RETURNS TABLE (employee_id INTEGER, name TEXT) AS $$
DECLARE

BEGIN

END;
$$ LANGUAGE plpgsql;
