/*
    18. get_my_registrations: This routine is used when a customer requests to view his/her active course registrations (i.e, registrations for course sessions that have not ended).
    The input to the routine is a customer identifier.
    The routine returns a table of records with the following information for each active registration session:
        course name,
        course fees,
        session date,
        session start hour,
        session duration, and
        instructor name.
    The output is sorted in
        ascending order of session date and
        session start hour.
*/
DROP FUNCTION IF EXISTS get_my_registrations CASCADE;
CREATE OR REPLACE FUNCTION get_my_registrations (
    r_customer_id INTEGER
)
RETURNS TABLE(
    course_title TEXT,
    offering_fees DEC(64,2),
    session_date DATE,
    session_start_hour INTEGER,
    course_duration INTEGER,
    instructor_name TEXT
) AS $$
BEGIN
    /* Check for NULLs in arguments */
    IF r_customer_id IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to get_my_registrations() cannot contain NULL values.';
    END IF;

    IF NOT EXISTS(SELECT customer_id FROM Customers c WHERE c.customer_id = r_customer_id)
    THEN
        RAISE EXCEPTION 'Customer ID % does not exist.', r_customer_id;
    END IF;

    RETURN QUERY (
        WITH CourseRegistrations(session_id, offering_launch_date, course_id) AS (
            SELECT Registers.session_id, Registers.offering_launch_date, Registers.course_id
            FROM Registers
            WHERE Registers.customer_id = r_customer_id AND Registers.register_cancelled IS NOT TRUE
            UNION
            SELECT r.session_id, r.offering_launch_date, r.course_id
            FROM Redeems r
            JOIN Buys b
            ON b.buy_timestamp = r.buy_timestamp
            WHERE b.customer_id = r_customer_id AND r.redeem_cancelled IS NOT TRUE
        ) 
        SELECT
            c.course_title,
            co.offering_fees,
            s.session_date,
            s.session_start_hour,
            c.course_duration,
            e.employee_name
        FROM CourseRegistrations
        NATURAL JOIN Sessions s
        NATURAL JOIN CourseOfferings co
        NATURAL JOIN Courses c
        INNER JOIN Employees e ON s.instructor_id = e.employee_id
        WHERE s.session_date >= CURRENT_DATE
            /* If current hour is session_end_hour, we consider the session to have ended. */
            AND s.session_end_hour > EXTRACT(HOUR FROM CURRENT_TIMESTAMP)
        ORDER BY s.session_date ASC, s.session_start_hour ASC
    );

    IF NOT FOUND THEN
        RAISE NOTICE 'No active course registrations found for customer %.', r_customer_id;
    END IF;
END;
$$ LANGUAGE PLPGSQL;
