CREATE OR REPLACE PROCEDURE add_course_offering(
    offering_launch_date DATE,
    offering_fees NUMERIC,
    start_date DATE,
    end_date DATE,
    offering_registration_deadline DATE,
    offering_num_target_registration INTEGER,
    offering_seating_capacity INTEGER,
    course_id INTEGER,
    admin_id INTEGER
) AS $$
BEGIN
    INSERT INTO CourseOfferings
    (offering_launch_date, offering_fees, offering_registration_deadline, offering_num_target_registration, offering_seating_capacity, course_id, admin_id)
    VALUES
    (offering_launch_date, offering_fees, offering_registration_deadline, offering_num_target_registration, offering_seating_capacity, course_id, admin_id);
END;
$$ LANGUAGE plpgsql;
