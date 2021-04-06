/*
    8. find_rooms: This routine is used to find all the rooms that could be used for a course session.
    The inputs to the routine include the following:
        session date,
        session start hour, and
        session duration.
    The routine returns a table of room identifiers.

    Query: Find all the rooms where there does not exists another sessions that is at the same time slot
*/
DROP FUNCTION IF EXISTS find_rooms CASCADE;
CREATE OR REPLACE FUNCTION find_rooms (
    session_date DATE,
    r_session_start_hour INTEGER,
    session_duration INTEGER
)
RETURNS TABLE(rid INTEGER) AS $$
DECLARE
    end_hour INTEGER := r_session_start_hour + session_duration;
    cur CURSOR FOR (
        SELECT r.room_id
        FROM Rooms r
        WHERE NOT EXISTS(
            SELECT 1 FROM Sessions s
            WHERE s.room_id = r.room_id
                AND (r_session_start_hour <= s.session_start_hour AND s.session_start_hour < end_hour)
                OR (s.session_start_hour <= session_start_hour AND session_start_hour < s.session_end_hour)
        ));
    rec RECORD;
BEGIN
    /* Check for NULLs in arguments */
    IF session_date IS NULL
        OR r_session_start_hour IS NULL
        OR session_duration IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to find_rooms() cannot contain NULL values.';
    END IF;

    OPEN cur;
    LOOP
        FETCH cur INTO rec;
        EXIT WHEN NOT FOUND;
        rid = rec.room_id;
        RETURN NEXT;
    END LOOP;
    CLOSE cur;
END;
$$ LANGUAGE PLPGSQL;
