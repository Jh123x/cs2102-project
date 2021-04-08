/*
    11. add_course_package: This routine is used to add a new course package for sale.
    The inputs to the routine include the following:
        package name,
        number of free course sessions,
        start and end date indicating the duration that the promotional package is available for sale, and
        the price of the package.
    The course package identifier is generated by the system.
    If the course package information is valid, the routine will perform the necessary updates to add the new course package.
*/
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
    /* Check for NULLs in arguments */
    IF package_name IS NULL
        OR package_num_free_registrations IS NULL
        OR package_sale_start_date IS NULL
        OR package_sale_end_date IS NULL
        OR package_price IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to add_course_package() cannot contain NULL values.';
    END IF;

    IF package_sale_end_date < CURRENT_DATE
    THEN
        RAISE EXCEPTION 'Cannot add a course package which has sales end date that had already past.';
    END IF;

    INSERT INTO CoursePackages
    (package_sale_start_date, package_num_free_registrations, package_sale_end_date, package_name, package_price)
    VALUES
    (package_sale_start_date, package_num_free_registrations, package_sale_end_date, package_name, package_price)
    RETURNING * INTO new_package;

    package_id := new_package.package_id;

    RETURN NEXT;
END
$$ LANGUAGE plpgsql;
