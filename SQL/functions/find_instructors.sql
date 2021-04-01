CREATE OR REPLACE FUNCTION find_instructors(course_id INTEGER, session_date DATE, session_start_hour TIMESTAMP)
RETURNS TABLE (employee_id INTEGER, name TEXT) AS $$
DECLARE

BEGIN
    /*
    * requirements:
    * - must be specialized in that area
    * - can only teach one session at any hour
    * - cannot teach two consecutuve sessions (i.e. must have at least one hour of break between any two course sessions)
    *   - cannot teach a course that ends at session_start_hour)
    * - part time instructor must not teach more than 30 hours for each month
    */

    SELECT e.employee_id, e.name
    FROM Employees e NATURAL JOIN Specializes s NATURAL JOIN Courses c
    WHERE c.course_id = course_id
          AND NOT EXISTS (
                SELECT 1 FROM Sessions s
                WHERE s.date = session_date AND s.employee_id = e.employee_id
                AND s.session_start_hour <= session_start_hour <= session_end_hour;)
          AND (
                SELECT COALESCE(SUM(end_time - start_time), 0) INTO hours FROM Sessions s
                WHERE s.employee_id = e.employee_id
                AND EXTRACT(MONTH FROM date) == EXTRACT(MONTH FROM CURRENT_DATE);
              ) < 30;
END;
$$ LANGUAGE plpgsql;
