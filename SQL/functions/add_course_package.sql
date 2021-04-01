CREATE OR REPLACE PROCEDURE add_course_package (
    package_id INTEGER,
    package_sale_start_date DATE,
    package_num_free_registrations INTEGER,
    package_sale_end_date DATE,
    package_name TEXT,
    package_price DEC(65, 2),
    package_date DATE /* What is this? */
) AS $$
BEGIN
    INSERT INTO CoursePackages
    VALUES (
        package_id,
        package_sale_start_date,
        package_num_free_registrations,
        package_sale_end_date,
        package_name,
        package_price,
        package_date /* this does not even exist in CoursePackages */
    );
END
$$ LANGUAGE plpgsql;
