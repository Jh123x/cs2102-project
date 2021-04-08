/*
    9. get_available_rooms: This routine is used to retrieve the availability information of rooms for a specific duration.
    The inputs to the routine include
        a start date and
        an end date.
    The routine returns a table of records consisting of the following information:
        room identifier,
        room capacity,
        day (which is within the input date range [start date, end date]),
        and an array of the hours that the room is available on the specified day.
    The output is sorted in ascending order of room identifier and day,
        and the array entries are sorted in ascending order of hour.
*/
DROP FUNCTION IF EXISTS get_available_rooms CASCADE;
CREATE OR REPLACE FUNCTION get_available_rooms (
    start_date DATE,
    end_date DATE
)
RETURNS TABLE (
    room_id                 INTEGER,
    room_seating_capacity   INTEGER,
    day                     DATE,
    available_hours         INTEGER[]
) AS $$
DECLARE
    curs CURSOR FOR (
        SELECT r.room_id, r.room_seating_capacity
        FROM Rooms r
    ) ORDER BY r.room_id ASC;
    r RECORD;

    cur_date DATE;
    cur_hour INTEGER;
    /* Rooms can only be used from 9am - 12pm and 2pm - 6pm. */
    start_hours INTEGER[] := ARRAY[9,10,11,14,15,16,17];
BEGIN
    /* Check for NULLs in arguments */
    IF start_date IS NULL OR end_date IS NULL THEN
        RAISE EXCEPTION 'Start and end dates cannot be NULL.';
    ELSIF start_date > end_date THEN
        RAISE EXCEPTION 'Start date cannot be later than end date.';
    END IF;

    OPEN curs;
    LOOP
        FETCH curs INTO r;
        EXIT WHEN NOT FOUND;

        cur_date := start_date;
        LOOP
            EXIT WHEN cur_date > end_date;

            room_id := r.room_id;
            room_seating_capacity := r.room_seating_capacity;
            day := cur_date;
            available_hours := '{}'; /* need to reset to empty array for each room-day pair */

            FOREACH cur_hour IN ARRAY start_hours LOOP
                /* Check room availability for 1 hour block on current iterated date */
                IF room_id IN (SELECT rid FROM find_rooms(cur_date, cur_hour, 1))
                THEN
                    available_hours := array_append(available_hours, cur_hour);
                END IF;
            END LOOP;

            /* Only include into results if room is free for at least one hour on the current iterated date */
            IF array_length(available_hours, 1) > 0 THEN
                RETURN NEXT;
            END IF;

            cur_date := cur_date + INTERVAL '1 day';
        END LOOP;
    END LOOP;
    CLOSE curs;
END;
$$ LANGUAGE plpgsql;
