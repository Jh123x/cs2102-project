/*
    15. get_available_course_offerings: This routine is used to retrieve all the available course offerings that could be registered.
    The routine returns a table of records with the following information for each course offering:
        course title,
        course area,
        start date,
        end date,
        registration deadline,
        course fees, and
        the number of remaining seats.
    The output is sorted in
        ascending order of registration deadline and
        course title.
*/
DROP FUNCTION IF EXISTS get_offering_num_remaining_seats CASCADE;
CREATE OR REPLACE FUNCTION get_offering_num_remaining_seats (
    offering_launch_date_arg DATE,
    course_id_arg INTEGER
) RETURNS INTEGER AS $$
DECLARE
    num_remaining_seats INTEGER;
BEGIN
    /* Check for NULLs in arguments */
    IF offering_launch_date_arg IS NULL
        OR course_id_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to get_offering_num_remaining_seats() cannot contain NULL values.';
    END IF;

    SELECT SUM(get_session_num_remaining_seats(s.session_id, s.offering_launch_date, s.course_id)) INTO num_remaining_seats
    FROM Sessions s
    WHERE s.offering_launch_date = offering_launch_date_arg
        AND s.course_id = course_id_arg;

    IF num_remaining_seats IS NULL
    THEN
        num_remaining_seats := 0;
    END IF;

    RETURN num_remaining_seats;
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS get_available_course_offerings CASCADE;
CREATE OR REPLACE FUNCTION get_available_course_offerings()
RETURNS TABLE(
    course_title TEXT,
    course_area_name TEXT,
    offering_start_date DATE,
    offering_end_date DATE,
    offering_registration_deadline DATE,
    offering_fees DEC(64,2),
    offering_num_remaining_seats INTEGER
) AS $$
BEGIN
    RETURN QUERY (
        SELECT 
            c.course_title,
            ca.course_area_name,
            co.offering_start_date,
            co.offering_end_date,
            co.offering_registration_deadline,
            co.offering_fees,
            get_offering_num_remaining_seats(co.offering_launch_date, co.course_id)
        FROM CourseOfferings co
        NATURAL JOIN Courses c
        NATURAL JOIN CourseAreas ca
        WHERE co.offering_registration_deadline >= CURRENT_DATE
            AND get_offering_num_remaining_seats(co.offering_launch_date, co.course_id) > 0
        ORDER BY co.offering_registration_deadline ASC, c.course_title ASC
    );

    IF NOT FOUND THEN
        RAISE NOTICE 'No course offerings are available for registration now.';
    END IF;
END;
$$ LANGUAGE PLPGSQL;
