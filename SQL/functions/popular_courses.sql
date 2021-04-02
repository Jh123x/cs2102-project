DROP FUNCTION IF EXISTS get_offering_num_enrolled CASCADE;
CREATE OR REPLACE FUNCTION get_offering_num_enrolled (
    offering_launch_date_arg DATE,
    course_id_arg INTEGER
) RETURNS INTEGER AS $$
DECLARE
    num_enrolled INTEGER;
BEGIN
    SELECT SUM(r.room_seating_capacity - get_session_num_remaining_seats(s.session_id, s.offering_launch_date, s.course_id)) INTO num_enrolled
    FROM Sessions s
    NATURAL JOIN Rooms r
    WHERE s.offering_launch_date = offering_launch_date_arg
        AND s.course_id = course_id_arg;

    IF num_enrolled IS NULL
    THEN
        num_enrolled := 0;
    END IF;

    RETURN num_enrolled;
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS popular_courses CASCADE;
CREATE OR REPLACE FUNCTION popular_courses ()
RETURNS TABLE(
    course_id INTEGER,
    course_title TEXT,
    course_area_name TEXT,
    num_course_offerings INTEGER,
    num_latest_registrations INTEGER
) AS $$

BEGIN
    RETURN QUERY (
        SELECT
            c.course_id,
            c.course_title,
            ca.course_area_name,
            /* number of course offerings this year */
            (
                SELECT COUNT(co.offering_launch_date)::INTEGER
                FROM CourseOfferings co
                WHERE co.course_id = c.course_id
                    AND DATE_PART('YEAR', co.offering_start_date) = DATE_PART('YEAR', CURRENT_DATE)
            ) AS num_course_offerings,
            /* number of registrations for latest offering this year */
            (
                SELECT get_offering_num_enrolled(co.offering_launch_date, co.course_id)
                FROM CourseOfferings co
                WHERE co.course_id = c.course_id
                    AND DATE_PART('YEAR', co.offering_start_date) = DATE_PART('YEAR', CURRENT_DATE)
                ORDER BY co.offering_launch_date DESC
                LIMIT 1
            ) AS num_latest_registrations
        FROM Courses c
        NATURAL JOIN CourseAreas ca
        WHERE (
                SELECT COUNT(co.offering_launch_date)
                FROM CourseOfferings co
                WHERE co.course_id = c.course_id
                    AND DATE_PART('YEAR', co.offering_start_date) = DATE_PART('YEAR', CURRENT_DATE)
            ) >= 2
            /* All pairs of earlier -> later course offerings this year must have increasing number of registrations */
            AND TRUE = ALL(
                SELECT (
                    get_offering_num_enrolled(co.offering_launch_date, co.course_id) >
                    get_offering_num_enrolled(co2.offering_launch_date, co2.course_id)
                ) AS isIncreasinglyPopular
                FROM CourseOfferings co, CourseOfferings co2
                WHERE c.course_id = co.course_id
                    AND co.course_id = co2.course_id
                    AND DATE_PART('YEAR', co.offering_start_date) = DATE_PART('YEAR', CURRENT_DATE)
                    AND DATE_PART('YEAR', co.offering_start_date) = DATE_PART('YEAR', co2.offering_start_date)
                    AND co.offering_start_date < co2.offering_start_date
            )
        ORDER BY num_latest_registrations DESC, c.course_id ASC
    );

    IF NOT FOUND THEN
        RAISE NOTICE 'No popular courses in this year.';
    END IF;
END;
$$ LANGUAGE PLPGSQL;
