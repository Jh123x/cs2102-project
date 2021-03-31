CREATE OR REPLACE PROCEDURE remove_employee(
    eid INTEGER,
    departure_date DATE
) AS $$

DECLARE
    isAdmin_count INTEGER;
    isManaging_count INTEGER;
    isTeaching_count INTEGER;

BEGIN
    -- Check if they are still handling admin tasks
    SELECT COUNT(*) INTO isAdmin_count FROM CourseOfferings c WHERE c.admin_id = eid;

    -- Check if they are still teaching some course
    SELECT COUNT(*) INTO isManaging_count FROM Course_areas c WHERE c.manager_id = eid;

    -- Check if they are manager managing some area
    SELECT COUNT(*) INTO isTeaching_count FROM Sessions s WHERE s.instructor_id = eid;

    IF (isAdmin_count + isManaging_count + isTeaching_count > 0) THEN
        RAISE EXCEPTION "Employing is still Admin/Managing/Teaching";
    END IF;

    -- DELETE FROM Employees e WHERE e.eid = eid;
    UPDATE Employees SET depart_date = departure_date WHERE e.eid = eid;

END;
$$ LANGUAGE plpgsql
