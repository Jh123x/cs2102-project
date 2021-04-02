DROP FUNCTION IF EXISTS get_offering_num_remaining_seats CASCADE;
CREATE OR REPLACE FUNCTION get_offering_num_remaining_seats (
    offering_launch_date DATE, 
    course_id INTEGER
) RETURNS INTEGER AS $$
BEGIN
    /* Todo: implement the logic for finding number of remaining seats for this course */
    RETURN 1337;
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
