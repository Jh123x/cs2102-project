CREATE OR REPLACE FUNCTION top_packages (
      N INTEGER
)
RETURNS TABLE (package_id INTEGER,
               package_num_free_registrations INTEGER,
               package_price DEC(64, 2),
               package_sale_start_date DATE,
               package_sale_end_date DATE,
               packages_num_sold INTEGER)
               AS $$
DECLARE

BEGIN
    WITH
        /* excluded packages that are not sold */
        PackagesSold AS
        (
            SELECT package_id, COUNT(*) as packages_num_sold
            FROM CoursePackages c NATURAL JOIN Buys b
            GROUP BY package_id
        ),
        /* use rank because according to requirements:
            "In the event that there are multiple packages that tie for the top Nth position,
            all these packages should be included in the output records"
        */
        PackagesWithRank AS
        (
            SELECT package_id, package_num_free_registrations, package_price, package_sale_start_date,
                   package_sale_end_date, packages_num_sold,
                   RANK() over (order by packages_num_sold DESC) as package_rank
            FROM CoursePackages NATURAL JOIN PackagesSold
        )
    SELECT package_id, package_num_free_registrations, package_price, package_sale_start_date,
           package_sale_end_date, packages_num_sold
    FROM PackagesWithRank
    WHERE package_rank <= N
    ORDER BY packages_num_sold DESC, package_price DESC;
END;
$$ LANGUAGE plpgsql;