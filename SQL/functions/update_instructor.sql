CREATE OR REPLACE PROCEDURE update_instructor(
    course_offering_id INTEGER,
    session_number INTEGER,
    new_instructor_employee_id INTEGER
) AS $$
DECLARE
    session_date DATE;
    session_start_time TIMESTAMP;
    is_valid_instructor INTEGER;
BEGIN
    SELECT s.date, s.start_time INTO session_date, session_start_time
    FROM Sessions s
    WHERE sid = s.session_number;

    IF (session_start_time >= CURRENT_TIME) THEN
        RAISE EXCEPTION 'Session already started! Cannot update instructor!';
    END IF;


    /*
        Can simplify the whole logic below to:
            IF new_instructor_employee_id NOT IN (SELECT employee_id FROM find_instructors(course_id, session_date, session_start_hour)) THEN
                RAISE EXCEPTION 'This instructor cannot teach this session!';
            END IF;
    */

    SELECT COUNT(*) INTO is_valid_instructor
    FROM find_instructors(course_id, session_date, session_start_hour)
    WHERE employee_id = new_instructor_employee_id;

    IF is_valid_instructor = 0 THEN
        RAISE EXCEPTION 'This instructor cannot teach this session!';
    END IF;
END;
$$ LANGUAGE plpgsql;
