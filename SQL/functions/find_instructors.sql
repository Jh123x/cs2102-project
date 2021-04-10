/*
    6. find_instructors: This routine is used to find all the instructors who could be assigned to teach a course session.
    The inputs to the routine include the following:
        course identifier,
        session date, and
        session start hour.
    The routine returns a table of records consisting of
        employee identifier and
        name.
*/
DROP FUNCTION IF EXISTS is_full_time_instructor CASCADE;
CREATE OR REPLACE FUNCTION is_full_time_instructor (instructor_id_arg INTEGER)
RETURNS BOOLEAN AS $$
    RETURN EXISTS(SELECT * FROM FullTimeInstructors i WHERE i.instructor_id = instructor_id_arg);
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS is_part_time_instructor CASCADE;
CREATE OR REPLACE FUNCTION is_part_time_instructor (instructor_id_arg INTEGER)
RETURNS BOOLEAN AS $$
    RETURN EXISTS(SELECT * FROM PartTimeInstructors i WHERE i.instructor_id = instructor_id_arg);
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS find_instructors CASCADE;
CREATE OR REPLACE FUNCTION find_instructors (
    course_id_arg INTEGER,
    session_date_arg DATE,
    session_start_hour_arg INTEGER
)
RETURNS TABLE (employee_id INTEGER, employee_name TEXT) AS $$
DECLARE
    session_end_hour_var INTEGER;
BEGIN
    /* Check for NULLs in arguments */
    IF course_id_arg IS NULL
        OR session_date_arg IS NULL
        OR session_start_hour_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to find_instructors() cannot contain NULL values.';
    END IF;

    /* Check if course_id supplied is valid */
    IF NOT EXISTS(
        SELECT c.course_id FROM Courses c
        WHERE c.course_id = course_id_arg
    ) THEN
        RAISE EXCEPTION 'Course ID not found.';
    END IF;
    /* Todo: Validate session_date and session_start_hour to ensure > current time? */
    /*Maybe do not need to enforce that because they didnt mention?*/

    /*Get the duration of the course*/
    SELECT session_start_hour_arg + course_duration INTO session_end_hour_var
    FROM Courses
    WHERE Courses.course_id = course_id_arg;

    /*
    * requirements:
    * - must be specialized in that area
    * - can only teach one session at any hour
    * - cannot teach two consecutuve sessions (i.e. must have at least one hour of break between any two course sessions)
    * - cannot teach a course that ends at session_start_hour)
    * - part time instructor must not teach more than 30 hours for each month
    */
    RETURN QUERY (
        SELECT DISTINCT e.employee_id, e.employee_name
        FROM Employees e
        JOIN Instructors i
        ON i.instructor_id = e.employee_id
        NATURAL JOIN Specializes sp
        WHERE e.employee_join_date <= session_date_arg /* Check for the hire date of the instructors */
            AND NOT EXISTS (
                SELECT 1
                FROM Sessions s
                WHERE (
                        s.session_date = session_date_arg
                        AND s.instructor_id = e.employee_id
                    )
                    AND
                    (
                        /* Check for overlap instead of just checking if start lands within */
                        (s.session_start_hour <= session_start_hour_arg AND session_start_hour_arg <= s.session_end_hour)
                        OR 
                        (session_start_hour_arg <= s.session_start_hour AND s.session_start_hour <= session_end_hour_var)
                        /* 1 hour break in between */
                        OR s.session_end_hour = session_start_hour_arg
                    )
            )
            AND (
                is_full_time_instructor(e.employee_id)
                OR (
                    is_full_time_instructor(e.employee_id)
                    AND (course_duration + (
                        SELECT COALESCE(SUM(session_end_hour - session_start_hour), 0)
                        FROM Sessions s
                        WHERE s.instructor_id = e.employee_id
                            AND EXTRACT(MONTH FROM session_date_arg) = EXTRACT(MONTH FROM CURRENT_DATE)
                    )) <= 30
                )
            )
            AND sp.course_area_name = (
                SELECT course_area_name
                FROM Courses
                WHERE course_id = course_id_arg
            )
    );
END;
$$ LANGUAGE plpgsql;
