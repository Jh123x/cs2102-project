CREATE OR REPLACE FUNCTION check_course_package() RETURNS TRIGGER AS $$
DECLARE
    sale_start DATE;
    sale_end DATE;
    buy_date DATE := (SELECT NEW.buy_timestamp ::DATE);
BEGIN

    /*Get the sale start and end date*/
    SELECT package_sale_start_date, package_sale_end_date INTO sale_start, sale_end FROM CoursePackages cp
    WHERE cp.package_id = NEW.package_id;


    IF NOT (buy_date BETWEEN sale_start AND sale_end) THEN
        RAISE EXCEPTION 'Course package sale date has passed';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER check_course_package_trigger
BEFORE INSERT ON Buys
FOR EACH ROW EXECUTE FUNCTION check_course_package();
