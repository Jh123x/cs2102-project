/*
    14. get_my_course_package: This routine is used when a customer requests to view his/her active/partially active course package.
    The input to the routine is a customer identifier.
    The routine returns the following information as a JSON value:
        package name,
        purchase date,
        price of package,
        number of free sessions included in the package,
        number of sessions that have not been redeemed, and
        information for each redeemed session (course name, session date, session start hour).
    The redeemed session information is sorted in
        ascending order of session date and
        start hour.
*/
DROP FUNCTION IF EXISTS customer_has_active_ish_course_package CASCADE;
CREATE OR REPLACE FUNCTION customer_has_active_ish_course_package (
    customer_id_arg INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT * FROM get_customer_active_ish_course_package(customer_id_arg) AS cp
    );
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS get_customer_active_ish_course_package CASCADE;
CREATE OR REPLACE FUNCTION get_customer_active_ish_course_package (
    customer_id_arg INTEGER
)
RETURNS TABLE(
    buy_date TIMESTAMP,
    package_name TEXT,
    package_price DEC(64,2),
    package_num_free_registrations INTEGER,
    buy_num_remaining_redemptions INTEGER
) AS $$
BEGIN
    RETURN QUERY (
        /*
            Active - at least one unused session in the package
            Partially active - at least one cancellable session (at least 7 days before session date)
        */
        SELECT cp.buy_date, cp.package_name, cp.package_price, cp.package_num_free_registrations, cp.buy_num_remaining_redemptions
        FROM get_customer_course_packages(customer_id_arg) AS cp
        WHERE cp.buy_num_remaining_redemptions > 1
            OR EXISTS(
                SELECT redeem_date
                FROM Redeems r
                NATURAL JOIN Buys b
                NATURAL JOIN Sessions s
                WHERE r.buy_date = cp.buy_date AND s.session_date >= CURRENT_DATE + 7
            )
        ORDER BY cp.buy_date DESC
        LIMIT 1
    );
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS customer_has_course_packages CASCADE;
CREATE OR REPLACE FUNCTION customer_has_course_packages (
    customer_id_arg INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT * FROM get_customer_course_packages(customer_id_arg) AS cp
    );
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS get_customer_course_packages CASCADE;
CREATE OR REPLACE FUNCTION get_customer_course_packages (
    customer_id_arg INTEGER
)
RETURNS TABLE(
    buy_date TIMESTAMP,
    package_name TEXT,
    package_price DEC(64,2),
    package_num_free_registrations INTEGER,
    buy_num_remaining_redemptions INTEGER
) AS $$
BEGIN
    RETURN QUERY (
        SELECT b.buy_date, cp.package_name, cp.package_price, cp.package_num_free_registrations, b.buy_num_remaining_redemptions
        FROM Buys b
        NATURAL JOIN CoursePackages cp
        WHERE b.customer_id = customer_id_arg
        ORDER BY buy_date DESC
    );
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS has_active_or_partially_active_course_package CASCADE;
CREATE OR REPLACE FUNCTION has_active_or_partially_active_course_package (
    customer_id_arg INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN

END;
$$ LANGUAGE PLPGSQL;

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
    IF customer_has_course_packages(customer_id_arg) IS NOT TRUE
    THEN
        RAISE NOTICE 'Customer % has not purchased any course packages.', customer_id_arg;
        course_package_details := row_to_json(row());
    /* Customer must have either active or partially active course package */
    ELSIF customer_has_active_ish_course_package(customer_id_arg) IS TRUE
    THEN
        SELECT cp.buy_date, cp.package_name, cp.package_price, cp.package_num_free_registrations, cp.buy_num_remaining_redemptions
        INTO cp_buy_date, package_name, package_price, package_num_free_registrations, buy_num_remaining_redemptions
        FROM get_customer_active_ish_course_package(customer_id_arg) AS cp;

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
    RETURN NEXT;
END;
$$ LANGUAGE PLPGSQL;
