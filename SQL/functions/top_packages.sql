/*
    27. top_packages: This routine is used to find the top N course packages in terms of the total number of packages sold for this year (i.e., the package's start date is within this year).
    The input to the routine is a positive integer number N.
    The routine returns a table of records consisting of the following information for each of the top N course packages:
        package identifier,
        number of included free course sessions,
        price of package,
        start date,
        end date, and
        number of packages sold.
    The output is sorted in
        descending order of number of packages sold followed by
        descending order of price of package.
    In the event that there are multiple packages that tie for the top Nth position, all these packages should be included in the output records;
    thus, the output table could have more than N records.
    It is also possible for the output table to have fewer than N records if N is larger than the number of packages launched this year.
*/
DROP FUNCTION IF EXISTS top_packages CASCADE;
CREATE OR REPLACE FUNCTION top_packages (
    N INTEGER
)
RETURNS TABLE (
    package_id INTEGER,
    package_num_free_registrations INTEGER,
    package_price DEC(64, 2),
    package_sale_start_date DATE,
    package_sale_end_date DATE,
    packages_num_sold INTEGER)
    AS $$
BEGIN
    /* Check for NULLs in arguments */
    IF N IS NULL OR N <= 0
    THEN
        RAISE EXCEPTION 'Number of top packages to find must be an integer more than 0.';
    END IF;

    WITH
        /* excluded packages that are not sold */
        PackagesSold AS
        (
            SELECT package_id, COUNT(*) AS packages_num_sold
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
                   RANK() OVER (ORDER BY packages_num_sold DESC) AS package_rank
            FROM CoursePackages NATURAL JOIN PackagesSold
        )
    SELECT package_id, package_num_free_registrations, package_price, package_sale_start_date,
           package_sale_end_date, packages_num_sold
    FROM PackagesWithRank
    WHERE package_rank <= N
    ORDER BY packages_num_sold DESC, package_price DESC;
END;
$$ LANGUAGE plpgsql;
