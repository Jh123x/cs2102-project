/*
    8. find_rooms: This routine is used to find all the rooms that could be used for a course session.
    The inputs to the routine include the following:
        session date,
        session start hour, and
        session duration.
    The routine returns a table of room identifiers.

    Query: Find all the rooms where there does not exists another sessions that is at the same time slot
*/
CREATE OR REPLACE FUNCTION find_rooms(
    session_date DATE,
    session_start_hour INTEGER,
    session_duration INTEGER
) RETURNS TABLE(rid INTEGER) AS $$
    DECLARE
        end_hour INTEGER := session_start_hour + session_duration;
        cur CURSOR FOR (SELECT r.rid FROM Rooms r
            WHERE NOT EXISTS(
                SELECT 1 FROM Sessions s
                WHERE s.rid = r.rid
                AND (session_start_hour < s.session_start_hour AND s.session_start_hour < session_end_hour)
                AND (s.session_start_hour < session_start_hour AND session_start_hour < s.session_end_hour)
            ));
        rec RECORD;
    BEGIN
        OPEN cur;
        LOOP
            FETCH cur INTO rec;
            EXIT WHEN NOT FOUND;
            RETURN NEXT;
        END LOOP;
        CLOSE cur;
    END;
$$ LANGUAGE PLPGSQL;
