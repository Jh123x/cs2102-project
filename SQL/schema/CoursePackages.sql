DROP TABLE IF EXISTS CoursePackages CASCADE;
CREATE TABLE CoursePackages (
    package_id SERIAL PRIMARY KEY,
    package_sale_start_date DATE NOT NULL,
    package_num_free_registrations INTEGER NOT NULL,
    package_sale_end_date DATE NOT NULL,
    package_name TEXT unique NOT NULL,
    package_price DEC(64,2) NOT NULL,

    CHECK(package_price >= 0),
    CHECK(package_num_free_registrations >= 0)
);
