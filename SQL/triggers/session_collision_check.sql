-- Make sure no 2 sessions are using the same room at the same time.
CREATE OR REPLACE FUNCTION session_collision_check() RETURNS TRIGGER AS $$
	DECLARE
		collisions INTEGER;
	BEGIN

		-- Check if the old time and date = new time and date    
		IF (TG_OP = 'UPDATE' AND NEW.date = OLD.date AND NEW.start_time = OLD.start_time) THEN
			RETURN NEW;

		-- Check if it is a valid operation
		ELSIF (TG_OP NOT IN ('INSERT', 'UPDATE')) THEN
			RAISE EXCEPTION 'Trigger is not suppose to be enforces in other methods.';
		END IF;

		-- Find collisions
		SELECT COUNT(*) INTO collisions 
		FROM Sessions s
		WHERE NEW.date = s.date
		AND (
			NEW.start_time BETWEEN s.start_time and s.end_time
			OR
			s.start_time BETWEEN NEW.start_time AND NEW.end_time
		)
		AND (NEW.course_id = s.course_id OR NEW.rid = s.rid);

		-- Filter if there are any collisions
		IF (collisions > 0) THEN
			RAISE NOTICE 'There is a collision with the current session.';
			RETURN NULL;
		END IF;

		-- If everything passes return NEW
		RETURN NEW;
	END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER session_collision_trigger
BEFORE INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION session_collision_check();