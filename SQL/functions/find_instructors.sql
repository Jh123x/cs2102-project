/*
This routine is used to find all the instructors who could be assigned to teach a course session.
The inputs to the routine include the following: course identifier, session date, and session start hour.
The routine returns a table of records consisting of employee identifier and name.
*/

CREATE OR REPLACE FUNCTION find_instructors (
      course_id INTEGER,
      session_date DATE,
      session_start_hour INTEGER
)
RETURNS TABLE (employee_id INTEGER, employee_name TEXT) AS $$
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

    SELECT e.employee_id, e.employee_name
    FROM Employees e
    NATURAL JOIN Specializes s
    NATURAL JOIN Courses c
    WHERE c.course_id = course_id
        AND NOT EXISTS (
            SELECT 1
            FROM Sessions s
            WHERE s.session_date = session_date 
                AND s.instructor_id = e.employee_id
                AND (s.session_start_hour <= session_start_hour AND session_start_hour <= session_end_hour)
        )
        AND (
            SELECT COALESCE(SUM(session_end_hour - session_start_hour), 0)
            FROM Sessions s
            WHERE s.instructor_id = e.employee_id
                AND EXTRACT(MONTH FROM session_date) = EXTRACT(MONTH FROM CURRENT_DATE)
        ) < 30;
END;
$$ LANGUAGE plpgsql;
