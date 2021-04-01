/*
    Todo: need to also accept information for each session (session date, session start hour, and room identifier)
    If the input course offering information is valid, the routine will assign instructors for the sessions. If a valid instructor assignment exists
*/

DROP FUNCTION IF EXISTS add_course_offering CASCADE;
CREATE OR REPLACE FUNCTION add_course_offering (
    offering_launch_date DATE,
    offering_fees NUMERIC,
    start_date DATE,
    end_date DATE,
    offering_registration_deadline DATE,
    offering_num_target_registration INTEGER,
    offering_seating_capacity INTEGER,
    course_id INTEGER,
    admin_id INTEGER
)
RETURNS TABLE (offering_launch_date DATE) AS $$
DECLARE
    new_package RECORD;
BEGIN
    INSERT INTO CourseOfferings
    (offering_launch_date, offering_fees, offering_registration_deadline, offering_num_target_registration, offering_seating_capacity, course_id, admin_id)
    VALUES
    (offering_launch_date, offering_fees, offering_registration_deadline, offering_num_target_registration, offering_seating_capacity, course_id, admin_id);
END;
$$ LANGUAGE plpgsql;
