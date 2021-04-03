/*
    Todo: need to also accept information for each session (session date, session start hour, and room identifier)
    If the input course offering information is valid, the routine will assign instructors for the sessions. If a valid instructor assignment exists
*/

DROP FUNCTION IF EXISTS add_course_offering CASCADE;
CREATE TYPE session_information AS(
    session_date DATE, 
    session_start_hour INTEGER,
    room_id INTEGER
)
CREATE OR REPLACE FUNCTION add_course_offering (
    offering_launch_date DATE,
    offering_fees NUMERIC,
    sessions_arr session_information[],
    offering_registration_deadline DATE,
    offering_num_target_registration INTEGER,
    offering_seating_capacity INTEGER,
    course_id INTEGER,
    admin_id INTEGER
)
RETURNS VOID AS $$
DECLARE
    offering_start_date DATE；
    offering_end_date DATE;
    num_duplicate INTEGER;

BEGIN
    /*still trying to fix the array to reference and compare*/
    SELECT session_date INTO offering_start_date
    FROM session_information si
    WHERE s.course_id = course_id AND s.offering_launch_date = offering_launch_date
    WHERE s.session_date <= ALL (
        SELECT s1.session_date 
        FROM Sessions s1
        WHERE s1.course_id = course_id
        AND s1.offering_launch_date = offering_launch_date
    )

    SELECT s.session_date INTO offering_end_date
    FROM Sessions s
    WHERE s.course_id = course_id AND s.offering_launch_date = offering_launch_date
    WHERE s.session_date >= ALL (
        SELECT s1.session_date 
        FROM Sessions s1
        WHERE s1.course_id = course_id
        AND s1.offering_launch_date = offering_launch_date
    )

    /*Checking the conditions of course offering*/
    IF (offering_start_date > offering_end_date) THEN
        RAISE EXCEPTION 'Offering end date cannot be earlier than start date';
    END IF ;

    IF (offering_launch_date > offering_registration_deadline) THEN
        RAISE EXCEPTION 'Offering registration date cannot be earlier than launch date';
    END IF ;
    
    IF (offering_seating_capacity < offering_num_target_registration) THEN
        RAISE EXCEPTION 'Offering seating capacity cannot be less than number of target registration';
    END IF ;

    IF (offering_num_target_registration < 0) THEN
        RAISE EXCEPTION 'Offering target registration should be more than or equal to 0';
    END IF ;
    
    IF (offering_start_date < offering_registration_deadline + INTEGER '10' ) THEN
        RAISE EXCEPTION 'Offering start date should be at least 10 days after the registration deadline ';
    END IF ;

    SELECT COUNT(*) INTO num_duplicate
    FROM CourseOfferings co
    WHERE co.offering_launch_date = offering_launch_date
    AND co.course_id = course_id;

    IF (num_duplicate > 0) THEN
        RAISE EXCEPTION 'Course offering has been launched! ';
    END IF ;
    
    INSERT INTO CourseOfferings
    (offering_launch_date, offering_fees, offering_registration_deadline, offering_num_target_registration, offering_seating_capacity, course_id, admin_id, offering_start_date, offering_end_date)
    VALUES
    (offering_launch_date, offering_fees, offering_registration_deadline, offering_num_target_registration, offering_seating_capacity, course_id, admin_id, offering_start_date, offering_end_date)
    

END;
$$ LANGUAGE plpgsql;
