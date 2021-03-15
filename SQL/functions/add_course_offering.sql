CREATE OR REPLACE PROCEDURE add_course_offering(
        launch_date DATE,
        fees NUMERIC,
        start_date DATE,
        end_date DATE,
        registration_deadline DATE,
        target_number_registration DATE,
        seating_capacity DATE,
        course_id INTEGER,
        admin_id INTEGER
    ) AS $$
INSERT INTO CourseOffering
VALUES (
        launch_date,
        fees,
        start_date,
        end_date,
        registration_deadline,
        target_number_registration,
        seating_capacity course_id,
        admin_id
    );
$$ LANGUAGE SQL