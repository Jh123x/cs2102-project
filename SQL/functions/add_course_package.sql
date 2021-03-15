CREATE OR REPLACE PROCEDURE add_course_package (
        package_id INTEGER,
        sale_start_date DATE,
        num_free_registrations INTEGER,
        sale_end_date DATE,
        name TEXT,
        price DEC(65, 2),
        date DATE
    ) AS $$
INSERT INTO Course_packages
VALUES (
        package_id,
        sale_start_date,
        num_free_registrations,
        sale_end_date,
        name,
        price,
        date
    );
$$ LANGUAGE SQL