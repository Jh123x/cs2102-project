/*
    16. get_available_course_sessions: This routine is used to retrieve all the available sessions for a course offering that could be registered.
    The input to the routine is a course offering identifier.
    The routine returns a table of records with the following information for each available session:
        session date,
        session start hour,
        instructor name, and
        number of remaining seats for that session.
    The output is sorted in
        ascending order of session date and
        start hour.
*/
DROP FUNCTION IF EXISTS get_session_num_remaining_seats CASCADE;
CREATE OR REPLACE FUNCTION get_session_num_remaining_seats (
    session_id_arg INTEGER,
    offering_launch_date_arg DATE, 
    course_id_arg INTEGER
) RETURNS INTEGER AS $$
DECLARE
    num_remaining_seats INTEGER;
BEGIN
    WITH Registrations AS (
        SELECT COUNT(r.register_date) AS num_registered
        FROM Registers r
        WHERE r.session_id = session_id_arg 
            AND r.offering_launch_date = offering_launch_date_arg 
            AND r.course_id = course_id_arg
            AND r.register_cancelled IS NOT TRUE
    ), Redemptions AS (
        SELECT COUNT(r.redeem_date) AS num_redeemed
        FROM Redeems r
        WHERE r.session_id = session_id_arg 
            AND r.offering_launch_date = offering_launch_date_arg 
            AND r.course_id = course_id_arg
            AND r.redeem_cancelled IS NOT TRUE
    ), SessionRoom AS (
        SELECT r.room_seating_capacity AS room_seating_capacity
        FROM Sessions s
        NATURAL JOIN Rooms r
        WHERE s.session_id = session_id_arg 
            AND s.offering_launch_date = offering_launch_date_arg 
            AND s.course_id = course_id_arg
    )
    SELECT (room_seating_capacity - COALESCE(num_registered, 0) - COALESCE(num_redeemed, 0)) INTO num_remaining_seats
    FROM Registrations, Redemptions, SessionRoom;

    IF num_remaining_seats IS NULL
    THEN
        num_remaining_seats := 0;
    END IF;

    RETURN num_remaining_seats;
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS get_available_course_sessions CASCADE;
CREATE OR REPLACE FUNCTION get_available_course_sessions (
    offering_launch_date_arg DATE, 
    course_id_arg INTEGER
)
RETURNS TABLE(
    session_date DATE,
    session_start_hour INTEGER,
    instructor_name TEXT,
    session_num_remaining_seats INTEGER
) AS $$
BEGIN
    RETURN QUERY (
        SELECT 
            s.session_date,
            s.session_start_hour,
            e.employee_name,
            get_session_num_remaining_seats(s.session_id, offering_launch_date, course_id)
        FROM Sessions s
        NATURAL JOIN CourseOfferings co
        NATURAL JOIN Instructors i 
        INNER JOIN Employees e ON i.instructor_id = e.employee_id
        WHERE s.offering_launch_date = offering_launch_date_arg
            AND s.course_id = course_id_arg
            AND co.offering_registration_deadline >= CURRENT_DATE
            AND get_session_num_remaining_seats(s.session_id, offering_launch_date, course_id) > 0
        ORDER BY s.session_date ASC, s.session_start_hour ASC
    );

    IF NOT FOUND THEN
        RAISE NOTICE 'No course offerings are available for registration now.';
    END IF;
END;
$$ LANGUAGE PLPGSQL;
