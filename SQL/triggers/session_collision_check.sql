/* Make sure no 2 sessions are using the same room at the same time. */
CREATE OR REPLACE FUNCTION session_collision_check()
RETURNS TRIGGER AS $$
DECLARE
    collisions INTEGER;
BEGIN

    /* Check if the old time and date = new time and date */
    IF (TG_OP = 'UPDATE' AND NEW.session_date = OLD.session_date AND NEW.session_start_hour = OLD.session_start_hour) THEN
        RETURN NEW;
    /* Check if it is a valid operation */
    ELSIF (TG_OP NOT IN ('INSERT', 'UPDATE')) THEN
        RAISE EXCEPTION 'Trigger is not suppose to be enforces in other methods.';
    END IF;

    /* Find collisions */
    SELECT COUNT(*) INTO collisions
    FROM Sessions s
    WHERE NEW.session_date = s.session_date
        AND (
            NEW.session_start_hour BETWEEN s.session_start_hour and s.session_end_hour
            OR s.session_start_hour BETWEEN NEW.session_start_hour AND NEW.session_end_hour
        )
        AND (
            NEW.course_id = s.course_id
            OR NEW.room_id = s.room_id
        ); /* Check if it is the same course at the same time or if it is in the same room */

    /* Filter if there are any collisions */
    IF (collisions > 0) THEN
        RAISE EXCEPTION 'There is a collision with the current session.';
    END IF;

    /* If everything passes return NEW */
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER session_collision_trigger
BEFORE INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION session_collision_check();
