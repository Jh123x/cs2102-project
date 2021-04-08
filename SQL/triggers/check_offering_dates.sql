CREATE OR REPLACE FUNCTION check_offering_dates()
RETURNS TRIGGER AS $$
DECLARE
    m_start_date DATE;
    m_end_date DATE;
    c_course_id INTEGER;
    c_session_id INTEGER;
    c_offering_launch_date DATE;
    c_sessions INTEGER;
BEGIN

    SELECT COALESCE(NEW.course_id, OLD.course_id), COALESCE(NEW.session_id, OLD.session_id), COALESCE(NEW.offering_launch_date, OLD.offering_launch_date)
    INTO c_course_id, c_session_id, c_offering_launch_date;

    SELECT MAX(s.session_date), MIN(s.session_date) INTO m_end_date, m_start_date
    FROM Sessions s
    WHERE c_course_id = s.course_id
    AND c_offering_launch_date = s.offering_launch_date;

    IF m_end_date IS NULL OR m_start_date IS NULL THEN
        RAISE EXCEPTION 'There is 0 sessions left in the table after the operation';
    END IF;

    UPDATE CourseOfferings c
    SET offering_start_date = m_start_date,
        offering_end_date = m_end_date
    WHERE c.course_id = c_course_id
        AND c.offering_launch_date = c_offering_launch_date;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_date_trigger
AFTER INSERT OR DELETE OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION check_offering_dates();
