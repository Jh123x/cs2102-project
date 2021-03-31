CREATE OR REPLACE PROCEDURE add_course_package (
    package_id INTEGER,
    sale_start_date DATE,
    num_free_registrations INTEGER,
    sale_end_date DATE,
    name TEXT,
    price DEC(65, 2),
    date DATE /* What is this? */
) AS $$
BEGIN
    INSERT INTO CoursePackages
    VALUES (
        package_id,
        sale_start_date,
        num_free_registrations,
        sale_end_date,
        name,
        price,
        date /* this does not even exist in CoursePackages */
    );
END
$$ LANGUAGE plpgsql;
