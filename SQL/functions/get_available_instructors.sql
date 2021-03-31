CREATE OR REPLACE FUNCTION get_available_instructors(course_id INTEGER, start_date DATE, end_date depart_date)
RETURN TABLE (employee_id INTEGER, name TEXT, total_teaching_hours INTEGER, day DATE, available_hours TIMESTAMP[]) AS $$
DECLARE

BEGIN

END;
$$ LANGUAGE plpgsql;
