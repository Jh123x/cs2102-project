DROP FUNCTION IF EXISTS add_course_package CASCADE;
CREATE OR REPLACE FUNCTION add_course_package (
    package_name TEXT,
    package_num_free_registrations INTEGER,
    package_sale_start_date DATE,
    package_sale_end_date DATE,
    package_price DEC(65, 2)
)
RETURNS TABLE (package_id INTEGER) AS $$
DECLARE
    new_package RECORD;
BEGIN
    INSERT INTO CoursePackages
    (package_sale_start_date, package_num_free_registrations, package_sale_end_date, package_name, package_price)
    VALUES
    (package_sale_start_date, package_num_free_registrations, package_sale_end_date, package_name, package_price)
    RETURNING * INTO new_package;

    package_id := new_package.package_id;
    RETURN NEXT;
END
$$ LANGUAGE plpgsql;
