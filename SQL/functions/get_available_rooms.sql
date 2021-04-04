/*
This routine is used to retrieve the availability information of rooms for a specific duration.
The inputs to the routine include a start date and an end date.
The routine returns a table of records consisting of the following information:
    room identifier,
    room capacity,
    day (which is within the input date range [start date, end date]),
    and an array of the hours that the room is available on the specified day.
The output is sorted in ascending order of room identifier and day, and the array entries are sorted in ascending order of hour.
*/
DROP FUNCTION IF EXISTS get_available_rooms;
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
    hour INTEGER;
    work_hours INTEGER[] := ARRAY[9,10,11,14,15,16,17];
BEGIN
    OPEN curs;
    LOOP
        FETCH curs INTO r;
        EXIT WHEN NOT FOUND;

        cur_date := start_date;
        LOOP
            EXIT WHEN cur_date > end_date;

            day := cur_date;
            room_id := r.room_id;
            room_seating_capacity := r.room_seating_capacity;

            FOREACH hour IN ARRAY work_hours LOOP
                IF room_id IN
                    (SELECT rid FROM find_rooms(cur_date, hour, 1)) THEN
                    available_hours := array_append(available_hours, hour);
                END IF;
            END LOOP;

            IF array_length(available_hours, 1) > 0 THEN
                RETURN NEXT;
            END IF;

            cur_date := cur_date + interval '1 day';
        END LOOP;
    END LOOP;
    CLOSE curs;
END;
$$ LANGUAGE plpgsql;
