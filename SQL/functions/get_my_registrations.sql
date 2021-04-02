DROP FUNCTION IF EXISTS get_my_registrations CASCADE;
CREATE OR REPLACE FUNCTION get_my_registrations (
    customer_id INTEGER
)
RETURNS TABLE(
    course_title TEXT,
    offering_fees DEC(64,2)
    session_date DATE,
    session_start_hour INTEGER,
    session_end_hour INTEGER,
    course_duration INTEGER
) AS $$
BEGIN
    RETURN QUERY (
        WITH (
            SELECT Registers.session_id, Registers.offering_launch_date, Registers.course_id
            FROM Registers
            WHERE Registers.customer_id = customer_id AND Registers.register_cancelled IS NOT TRUE
            UNION
            SELECT Redeems.session_id, Redeems.offering_launch_date, Redeems.course_id
            FROM Redeems
            WHERE Redeems.customer_id = customer_id AND Redeems.redeem_cancelled IS NOT TRUE
        ) AS CourseRegistrations
        SELECT
            c.course_title,
            co.offering_fees,
            s.session_date,
            s.session_start_hour,
            s.session_end_hour,
            c.course_duration
        FROM CourseRegistrations
        NATURAL JOIN Sessions s
        NATURAL JOIN CourseOfferings co
        NATURAL JOIN Courses c
        INNER JOIN Employees e ON s.instructor_id = e.employee_id
        WHERE s.session_date >= CURRENT_DATE
            /* If curernt hour is session_end_hour, we consider the session to have ended. */
            AND s.session_end_hour > EXTRACT(HOUR FROM CURRENT_TIMESTAMP)
        ORDER BY s.session_date ASC, s.session_start_hour ASC
    );

    IF NOT FOUND THEN
        RAISE NOTICE 'No active course registrations found for customer %.', customer_id;
    END IF;
END;
$$ LANGUAGE PLPGSQL;
