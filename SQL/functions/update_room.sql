CREATE OR REPLACE PROCEDURE update_room(
    offering_launch_date DATE,
    course_id INTEGER,
    session_id INTEGER,
    room_id INTEGER
) AS $$
DECLARE
    room_seating_capacity INTEGER;
    session_date DATE,
    session_start_hour INTEGER,
    num_registration INTEGER;
    num_redeems INTEGER;

    
BEGIN
    SELECT r.room_seating_capacity INTO room_seating_capacity
    FROM Rooms r
    WHERE room_id = r.room_id;

    SELECT COUNT(*) INTO num_registration
    FROM Registers reg
    WHERE reg.session_id = session_id
    AND reg.offering_launch_date = offering_launch_date
    AND reg.course_id = course_id;

    SELECT COUNT(*) INTO num_redeems
    FROM Redeems red 
    WHERE red.session_id = session_id
    AND red.offering_launch_date = offering_launch_date
    AND red.course_id = course_id;

    SELECT s.session_date, s.session_start_hour INTO session_date, session_start_hour
    FROM Sessions s
    WHERE s.offering_launch_date = offering_launch_date
    AND s.course_id = course_id
    AND s.session_id = session_id;

    IF (session_date < CURRENT_DATE OR (session_date = CURRENT_DATE AND session_start_hour <= EXTRACT(HOUR FROM CURRENT_TIME))) 
    THEN  
        RAISE EXCEPTION 'Session already started! Cannot update room!';
    END IF;

    IF ((num_redeems + num_registration) > room_seating_capacity)
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