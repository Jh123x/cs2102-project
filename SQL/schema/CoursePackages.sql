DROP TABLE IF EXISTS CoursePackages CASCADE;
CREATE TABLE CoursePackages (
    package_id SERIAL PRIMARY KEY,
    package_name TEXT NOT NULL,
    package_num_free_registrations INTEGER NOT NULL,
    package_sale_start_date DATE NOT NULL,
    package_sale_end_date DATE NOT NULL,
    package_price DEC(64,2) NOT NULL,

    CHECK(package_price >= 0),
    CHECK(package_num_free_registrations >= 0),
    CHECK(package_sale_start_date <= package_sale_end_date)
);
