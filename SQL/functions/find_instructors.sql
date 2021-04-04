/*
This routine is used to find all the instructors who could be assigned to teach a course session.
The inputs to the routine include the following: course identifier, session date, and session start hour.
The routine returns a table of records consisting of employee identifier and name.
*/

CREATE OR REPLACE FUNCTION find_instructors (
    r_course_id INTEGER,
    r_session_date DATE,
    r_session_start_hour INTEGER
)
RETURNS TABLE (employee_id INTEGER, employee_name TEXT) AS $$
DECLARE

BEGIN
    /*
    * requirements:
    * - must be specialized in that area
    * - can only teach one session at any hour
    * - cannot teach two consecutuve sessions (i.e. must have at least one hour of break between any two course sessions)
    * - cannot teach a course that ends at session_start_hour)
    * - part time instructor must not teach more than 30 hours for each month
    */
    RETURN QUERY
    SELECT DISTINCT e.employee_id, e.employee_name
    FROM Employees e
    JOIN Instructors i
    ON i.instructor_id = e.employee_id
    NATURAL JOIN Specializes sp
    WHERE NOT EXISTS (
            SELECT 1
            FROM Sessions s
            WHERE s.session_date = r_session_date
                AND s.course_id = r_course_id
                AND s.instructor_id = e.employee_id
                AND (s.session_start_hour <= r_session_start_hour AND r_session_start_hour <= session_end_hour)
        )
        AND (
            SELECT COALESCE(SUM(session_end_hour - session_start_hour), 0)
            FROM Sessions s
            WHERE s.instructor_id = e.employee_id
                AND EXTRACT(MONTH FROM r_session_date) = EXTRACT(MONTH FROM CURRENT_DATE)
        ) < 30
        AND sp.course_area_name = (
            SELECT course_area_name
            FROM Courses
            WHERE r_course_id = course_id
        );
END;
$$ LANGUAGE plpgsql;
