CREATE OR REPLACE PROCEDURE add_course_offering(
    launch_date DATE,
    fees NUMERIC,
    start_date DATE,
    end_date DATE,
    registration_deadline DATE,
    target_number_registration INTEGER,
    seating_capacity INTEGER,
    course_id INTEGER,
    admin_id INTEGER
) AS $$
BEGIN
    INSERT INTO CourseOfferings
        (launch_date, fees, registration_deadline, target_number_registration, seating_capacity, course_id, admin_id)
    VALUES 
        (launch_date, fees, registration_deadline, target_number_registration, seating_capacity, course_id, admin_id);
END;
$$ LANGUAGE plpgsql;
