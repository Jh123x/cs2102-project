/*
    22. update_room: This routine is used to change the room for a course session.
    The inputs to the routine include the following:
        course offering identifier,
        session number, and
        identifier of the new room.
    If the course session has not yet started and the update request is valid, the routine will process the request with the necessary updates.
    Note that update request should not be performed if the number of registrations for the session exceeds the seating capacity of the new room.
*/
DROP FUNCTION IF EXISTS array_includes_range CASCADE;
CREATE OR REPLACE FUNCTION array_includes_range(
    int_array INTEGER[],
    int_start INTEGER,
    int_end INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    total_ints INTEGER;
BEGIN
    total_ints := int_end - int_start;

    /*Between is inclusive*/
    RETURN total_ints = (
        SELECT ( COUNT(DISTINCT arr.i))
        FROM (SELECT unnest(int_array) AS i) AS arr
        WHERE arr.i BETWEEN int_start AND int_end - 1
    );
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS update_room CASCADE;
CREATE OR REPLACE FUNCTION update_room(
    offering_launch_date_arg DATE,
    course_id_arg INTEGER,
    session_id_arg INTEGER,
    room_id_arg INTEGER
) RETURNS VOID AS $$
DECLARE
    current_room_id INTEGER;
    session_date DATE;
    num_enrolled INTEGER;
    session_start_hour INTEGER;
    session_end_hour INTEGER;
    available_hours INTEGER[];
BEGIN
    /* Check for NULLs in arguments */
    IF offering_launch_date_arg IS NULL
        OR course_id_arg IS NULL
        OR session_id_arg IS NULL
        OR room_id_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to update_room() cannot contain NULL values.';
    END IF;

    /* Check if arguments yield a valid session */
    SELECT s.session_date, s.session_start_hour, s.session_end_hour
    INTO session_date, session_start_hour, session_end_hour
    FROM Sessions s
    WHERE s.offering_launch_date = offering_launch_date_arg
        AND s.course_id = course_id_arg
        AND s.session_id = session_id_arg;

    IF session_date IS NULL THEN
        RAISE EXCEPTION 'Session not found. Check if the course offering identifier (course_id and offering_launch_date) are correct.';
    END IF;

    /* Check if room seating capacity can accomodate all active registrations now */
    SELECT COUNT(*) INTO num_enrolled
    FROM Enrolment e
    WHERE e.session_id = session_id_arg
        AND e.offering_launch_date = offering_launch_date_arg
        AND e.course_id = course_id_arg;

    IF num_enrolled > (SELECT r.room_seating_capacity FROM Rooms r WHERE room_id_arg = r.room_id)
    THEN
        RAISE EXCEPTION 'Cannot accomodate all active registrations in room %.', room_id_arg;
    END IF;

    /* Check room availability */
    SELECT r.available_hours INTO available_hours
    FROM get_available_rooms(session_date, session_date) r
    WHERE r.room_id = room_id_arg;

    /* Also check that entire range of hours used by the session is available */
    IF available_hours IS NULL OR array_includes_range(available_hours, session_start_hour, session_end_hour)
    THEN
        RAISE EXCEPTION 'Room % is already in use', room_id_arg;
    ELSIF (
        /* Prevent updating of sessions that already started/ended. */
        CURRENT_DATE > session_date
        OR (CURRENT_DATE = session_date AND session_start_hour <= EXTRACT(HOUR FROM CURRENT_TIME))
    ) THEN
        RAISE EXCEPTION 'Cannot update room when the session already started.';
    END IF;

    /* Warn user when updating to same room */
    SELECT s.session_date, s.room_id INTO session_date, current_room_id
    FROM Sessions s
    WHERE s.course_id = course_id_arg
        AND s.session_id = session_id_arg
        AND s.offering_launch_date = offering_launch_date_arg;

    IF (current_room_id = room_id_arg) THEN
        RAISE NOTICE 'Assigning the same room to the session has no effect!';
        RETURN;
    END IF;

    UPDATE Sessions s
    SET room_id = room_id_arg
    WHERE s.session_id = session_id_arg
        AND s.offering_launch_date = offering_launch_date_arg
        AND s.course_id = course_id_arg;
END;
$$ LANGUAGE plpgsql;
