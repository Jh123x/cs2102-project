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
        /* not sure if should include packages that nobody bought, just assume to include for now */
        PackagesSold AS
        (
            SELECT package_id, COUNT(*) as packages_num_sold
            FROM CoursePackages c NATURAL LEFT OUTER JOIN Buys b
            GROUP BY package_id
        ),
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