DROP TABLE IF EXISTS CoursePackages CASCADE;
CREATE TABLE CoursePackages (
    package_id INTEGER PRIMARY KEY,
    sale_start_date DATE NOT NULL,
    num_free_registrations INTEGER NOT NULL,
    sale_end_date DATE NOT NULL,
    name TEXT unique NOT NULL,
    price DEC(65, 2) NOT NULL,
    CHECK(price > 0),
    CHECK(num_free_registrations >= 0)
);