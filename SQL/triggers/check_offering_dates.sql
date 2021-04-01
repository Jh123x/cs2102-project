CREATE OR REPLACE FUNCTION check_offering_dates()
RETURNS TRIGGER AS $$
DECLARE
    m_start_date DATE;
    m_end_date DATE;
BEGIN
    SELECT MAX(date), MIN(date) INTO m_end_date, m_start_date
    FROM Sessions s
    WHERE NEW.session_id = s.session_id
        AND NEW.course_id = s.course_id
        AND NEW.offering_launch_date = s.offering_launch_date;

    UPDATE CourseOffering c
    SET offering_start_date = m_start_date,
        offering_end_date = m_end_date
    WHERE c.course_id = OLD.course_id
        AND c.offering_launch_date = OLD.offering_launch_date;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_update_date_trigger
AFTER UPDATE ON Sessions
FOR EACH ROW WHEN (NEW.session_date IS DISTINCT FROM OLD.session_date)
EXECUTE FUNCTION check_offering_dates();

CREATE TRIGGER update_others_date_trigger
AFTER INSERT OR DELETE ON Sessions
FOR EACH ROW EXECUTE FUNCTION check_offering_dates();
