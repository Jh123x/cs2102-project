CREATE OR REPLACE FUNCTION check_offering_dates() RETURNS TRIGGER AS $$
DECLARE 
    m_start_date DATE;
    m_end_date DATE;
BEGIN
    SELECT MAX(date),
        MIN(date) INTO m_end_date,
        m_start_date
    FROM Sessions s
    WHERE NEW.sid = s.sid
        AND NEW.course_id = s.course_id
        AND NEW.launch_date = s.launch_date;

    UPDATE CourseOffering c SET start_date = m_start_date, end_date = m_end_date
    WHERE c.course_id = OLD.course_id AND c.launch_date = OLD.launch_date;
END;
$$ LANGUAGE PLPGSQL;


CREATE TRIGGER update_update_date_trigger
AFTER UPDATE ON Sessions 
FOR EACH ROW WHEN (NEW.date IS DISTINCT FROM OLD.date)
EXECUTE FUNCTION check_offering_dates();


CREATE TRIGGER update_others_date_trigger
AFTER INSERT OR DELETE ON Sessions
FOR EACH ROW EXECUTE FUNCTION check_offering_dates();