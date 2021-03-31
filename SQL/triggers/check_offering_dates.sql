CREATE OR REPLACE FUNCTION check_offering_dates() RETURNS TRIGGER AS $$
DECLARE start_date DATE;
    end_date DATE BEGIN
    SELECT MAX(s.end_date),
        MIN(s.start_date) INTO end_date,
        start_date
    FROM Sessions s
    WHERE NEW.sid = s.sid
        AND NEW.course_id = s.course_id
        AND NEW.launch_date = s.launch_date;
END;
$$ LANGUAGE PLPGSQL;
CREATE TRIGGER update_date_trigger
AFTER INSERT OR UPDATE ON Sessions 
FOR EACH ROW EXECUTE FUNCTION check_offering_dates()
WHEN (
        TG_OP = 'INSERT'
        OR NEW.start_date <> OLD.start_date
        OR NEW.end_date <> OLD.end_date
    );