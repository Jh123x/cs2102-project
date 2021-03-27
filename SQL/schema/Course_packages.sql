DROP TABLE IF EXISTS CoursePackages CASCADE;
CREATE TABLE CoursePackages (
    package_id INTEGER primary key,
    sale_start_date DATE not null,
    num_free_registrations INTEGER not null,
    sale_end_date DATE not null,
    name TEXT unique not null,
    price DEC(65, 2) not null,
    check(price > 0)
);