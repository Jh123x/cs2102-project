DROP FUNCTION IF EXISTS get_session_num_remaining_seats CASCADE;
CREATE OR REPLACE FUNCTION get_session_num_remaining_seats (
    session_id INTEGER,
    offering_launch_date DATE, 
    course_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    /* Todo: implement the logic for finding number of remaining seats for this session */
    RETURN 1337;
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS get_available_course_sessions CASCADE;
CREATE OR REPLACE FUNCTION get_available_course_sessions(
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
        NATURAL JOIN Instructors i 
        INNER JOIN Employees e ON i.instructor_id = e.employee_id
        WHERE s.offering_launch_date = offering_launch_date_arg AND s.course_id = course_id_arg
            AND get_session_num_remaining_seats(s.session_id, offering_launch_date, course_id) > 0
        ORDER BY s.session_date ASC, s.session_start_hour ASC
    );

    IF NOT FOUND THEN
        RAISE NOTICE 'No course offerings are available for registration now.';
    END IF;
END;
$$ LANGUAGE PLPGSQL;
