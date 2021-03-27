CREATE OR REPLACE PROCEDURE update_instructor(
    course_offering_id INTEGER,
    session_number INTEGER,
    new_instructor_eid INTEGER
) AS $$

DECLARE
    session_date DATE;
    session_start_time TIMESTAMP;
    is_valid_instructor INTEGER;
BEGIN
    SELECT s.date INTO session_date, s.start_time INTO session_start_time
    FROM Sessions s
    WHERE sid = s.session_number;

    IF session_start_time >= CURRENT_TIME() THEN
        RAISE EXCEPTION "Session already started! Cannot update instructor!"
    ENDIF

    SELECT COUNT(*) INTO is_valid_instructor
    FROM find_instructors(course_id, session_date, session_start_hour)
    WHERE eid = new_instructor_eid;
    IF is_valid_instructor = 0 THEN
        RAISE EXCEPTION "This instructor cannot teach this session!"
    ENDIF


END
$$ LANGUAGE plpgsql