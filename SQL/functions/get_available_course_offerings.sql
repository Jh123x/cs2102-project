DROP FUNCTION IF EXISTS get_available_course_packages CASCADE;
CREATE OR REPLACE FUNCTION get_available_course_packages()
RETURNS TABLE(
    package_name TEXT,
    package_num_free_registrations INTEGER,
    package_sale_end_date DATE,
    package_price DEC(64,2)
) AS $$
BEGIN
    RETURN QUERY (
        SELECT cp.package_name, cp.package_num_free_registrations, cp.package_sale_end_date, cp.package_price
        FROM CoursePackages cp
        WHERE cp.package_sale_end_date >= CURRENT_DATE
    );

    IF NOT FOUND THEN
        RAISE NOTICE 'No course packages are on sale now.';
    END IF;
END;
$$ LANGUAGE PLPGSQL;
