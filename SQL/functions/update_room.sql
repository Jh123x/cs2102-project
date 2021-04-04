CREATE OR REPLACE FUNCTION update_room(
    offering_launch_date DATE,
    course_id INTEGER,
    session_id INTEGER,
    room_id INTEGER
) RETURNS VOID
AS $$
DECLARE
    room_seating_capacity INTEGER;
    session_date DATE;
    session_start_hour INTEGER;
    num_registration INTEGER;
    original_room_id INTEGER;
    room_avail INTEGER;
    offering_end_date DATE;
    offering_start_date DATE;
    temp INTEGER
BEGIN
    SELECT s.room_id INTO original_room_id
    FROM Sessions s
    WHERE s.course_id = course_id
    AND s.session_id = session_id
    AND s.offering_launch_date = offering_launch_date;

    IF (original_room_id = room_id) THEN
        RAISE EXCEPTION 'Same room';
    
    SELECT o.offering_start_date, o.offering_end_date INTO offering_start_date, offering_end_date
    FROM CourseOfferings
    WHERE o.course_id = course_id;

    SELECT r.room_id INTO temp
    FROM get_available_rooms(offering_start_date,offering_end_date) r
    WHERE room_id = r.room_id;

    IF (temp <> room_id) THEN 
        RAISE EXCEPTION 'Room is in use';

    SELECT r.room_seating_capacity INTO room_seating_capacity
    FROM Rooms r
    WHERE room_id = r.room_id;

    SELECT COUNT(*) INTO num_registration
    FROM Registers reg
    WHERE reg.session_id = session_id
    AND reg.offering_launch_date = offering_launch_date
    AND reg.course_id = course_id;

    SELECT s.session_date, s.session_start_hour INTO session_date, session_start_hour
    FROM Sessions s
    WHERE s.offering_launch_date = offering_launch_date
    AND s.course_id = course_id
    AND s.session_id = session_id;

    IF (session_date < CURRENT_DATE OR (session_date = CURRENT_DATE AND session_start_hour <= EXTRACT(HOUR FROM CURRENT_TIME))) 
    THEN  
        RAISE EXCEPTION 'Session already started! Cannot update room!';
    END IF;

    IF (num_registration > room_seating_capacity)
    THEN  
        RAISE EXCEPTION 'Room is too small! Cannot update room!';
    END IF;

    UPDATE Sessions s 
    SET s.room_id = room_id
    WHERE s.session_id = session_id 
    AND s.offering_launch_date = offering_launch_date
    AND s.course_id = course_id;
    
END;
$$ LANGUAGE plpgsql;