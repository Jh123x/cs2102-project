DROP FUNCTION IF EXISTS get_my_course_package CASCADE;
CREATE OR REPLACE FUNCTION get_my_course_package (
    customer_id_arg INTEGER
)
RETURNS TABLE(course_package_details JSON) AS $$
DECLARE
    cp_buy_date TIMESTAMP;
    package_name TEXT;
    package_price DEC(64,2);
    package_num_free_registrations INTEGER;
    buy_num_remaining_redemptions INTEGER;
    redeemed_sessions JSON;
BEGIN
    SELECT b.buy_date, cp.package_name, cp.package_price, cp.package_num_free_registrations, b.buy_num_remaining_redemptions
    INTO cp_buy_date, package_name, package_price, package_num_free_registrations, buy_num_remaining_redemptions
    FROM Buys b
    NATURAL JOIN CoursePackages cp
    WHERE b.customer_id = customer_id_arg
    ORDER BY buy_date DESC
    LIMIT 1;

    IF cp_buy_date IS NULL
    THEN
        RAISE NOTICE 'Customer % has not purchased any course packages.', customer_id_arg;
        course_package_details := row_to_json(row());
    ELSE
        /*
            Must have either active or partially active course package
            Active - at least one unused session in the package
            Partially active - at least one cancellable session (at least 7 days before session date)
        */
        IF buy_num_remaining_redemptions > 1 OR EXISTS(
            SELECT redeem_date
            FROM Redeems r
            NATURAL JOIN Buys b
            NATURAL JOIN Sessions s
            WHERE r.buy_date = cp_buy_date AND s.session_date >= CURRENT_DATE + 7
        )
        THEN
            /* Aggregate all sessions redeemed using course package sorted in ascending order of session date and start hour */
            SELECT COALESCE(json_agg(session_information), '[]'::JSON) INTO redeemed_sessions
            FROM (
                SELECT c.course_title, s.session_date, s.session_start_hour
                FROM Redeems r
                NATURAL JOIN Buys b
                NATURAL JOIN Sessions s
                NATURAL JOIN CourseOfferings co
                NATURAL JOIN Courses c
                WHERE r.buy_date = cp_buy_date AND r.redeem_cancelled IS NOT TRUE
                ORDER BY s.session_date ASC, s.session_start_hour ASC
            ) AS session_information;

            /* Return value is JSON object */
            SELECT jsonb_build_object(
                'buy_date', cp_buy_date,
                'package_name', package_name,
                'package_price', package_price,
                'package_num_free_registrations', package_num_free_registrations,
                'buy_num_remaining_redemptions', buy_num_remaining_redemptions,
                'redeemed_sessions', redeemed_sessions
            ) INTO course_package_details;
        ELSE
            RAISE NOTICE 'Customer % has no active or partially active course packages.', customer_id_arg;
            course_package_details := row_to_json(row());
        END IF;
    END IF;
    RETURN NEXT;
END;
$$ LANGUAGE PLPGSQL;
