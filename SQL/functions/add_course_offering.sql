/*
    10. add_course_offering: This routine is used to add a new offering of an existing course.
    The inputs to the routine include the following:
        course offering identifier,
        course identifier,
        course fees,
        launch date,
        registration deadline,
        administrator's identifier,and
        information for each session (session date, session start hour, and room identifier).
    If the input course offering information is valid, the routine will assign instructors for the sessions.
    If a valid instructor assignment exists, the routine will perform the necessary updates to add the course offering;
        otherwise, the routine will abort the course offering addition.
    Note that the seating capacity of the course offering must be at least equal to the course offering's target number of registrations.

    Todo: need to also accept information for each session (session date, session start hour, and room identifier)
*/

DROP TYPE IF EXISTS session_information;
CREATE TYPE session_information AS(
    session_date DATE,
    session_start_hour INTEGER,
    room_id INTEGER
);


DROP FUNCTION IF EXISTS add_course_offering CASCADE;
CREATE OR REPLACE FUNCTION add_course_offering (
    launch_date DATE,
    fees NUMERIC,
    sessions_arr session_information ARRAY,
    registration_deadline DATE,
    off_course_id INTEGER,
    off_admin_id INTEGER
)
RETURNS TABLE(offering_launch_date DATE, offering_fees NUMERIC, offering_registration_deadline DATE, offering_num_target_registration INTEGER, offering_seating_capacity INTEGER, course_id INTEGER, admin_id INTEGER, offering_start_date DATE, offering_end_date DATE) AS $$
DECLARE
    off_start_date DATE;
    off_end_date DATE;
    session_end_hour INTEGER;
    num_sessions INTEGER;
    course_duration INTEGER;
    instructor_id INTEGER;
    session_id INTEGER;
    missing_instructor BOOLEAN;
    new_course_offering RECORD;
    r_capacity INTEGER;
    temp INTEGER;
BEGIN
    /*Extracting the start date and end date*/
    SELECT MIN(session_date) INTO off_start_date FROM unnest(sessions_arr);
    SELECT MAX(session_date) INTO off_end_date FROM unnest(sessions_arr);

    SELECT COUNT(*) INTO num_sessions FROM unnest(sessions_arr);
    SELECT cu.course_duration INTO course_duration FROM Courses cu WHERE off_course_id = cu.course_id;
    missing_instructor := FALSE;
    r_capacity := 0;


    /*Checking the conditions of course offering*/
    IF (launch_date > registration_deadline) THEN
        RAISE EXCEPTION 'Offering registration date cannot be earlier than launch date';
    END IF ;
    
    IF (seating_capacity < num_target_registration) THEN
        RAISE EXCEPTION 'Offering seating capacity cannot be less than number of target registration';
    END IF ;
    
    IF (num_target_registration < 0) THEN
        RAISE EXCEPTION 'Offering target registration should be more than or equal to 0';
    
    END IF ;
    
    IF (off_start_date > off_end_date) THEN
        RAISE EXCEPTION 'Offering end date cannot be earlier than start date';

    END IF;

    IF (off_start_date < registration_deadline + INTEGER '10' ) THEN
        RAISE EXCEPTION 'Offering start date should be at least 10 days after the registration deadline ';
    END IF;    

    /*Check if there is instructor for each session and check for session constraints*/
    FOR counter in 1..num_sessions 
        
    LOOP

        SELECT r_employee_id INTO instructor_id FROM get_available_instructors(off_course_id,sessions_arr[counter].session_date,sessions_arr[counter].session_date) LIMIT 1;
        IF (instructor_id = NULL) THEN
            missing_instructor := TRUE;
        END IF;
        session_end_hour := sessions_arr[counter].session_start_hour + course_duration;
        IF ((sessions_arr[counter].session_start_hour >= 9 AND sessions_arr[counter].session_start_hour < 12 AND session_end_hour > 12) OR sessions_arr[counter].session_start_hour > 18 OR session_end_hour > 18 OR sessions_arr[counter].session_start_hour < 9)THEN
            RAISE EXCEPTION 'Session time is out of range';
        END IF;
        IF(to_char(sessions_arr[counter].session_date, 'Dy') = 'Sat' OR to_char(sessions_arr[counter].session_date, 'Dy') = 'Sun') THEN
            RAISE EXCEPTION 'Can only have class from Mon - Fri';
        END IF;
        IF sessions_arr[counter].room_id NOT IN (SELECT rid FROM find_rooms(sessions_arr[counter].session_date,sessions_arr[counter].session_start_hour, course_duration)) THEN
            RAISE EXCEPTION 'Room in use';
        END IF;
        SELECT room_seating_capacity INTO temp FROM Rooms WHERE room_id = sessions_arr[counter].room_id;
        r_capacity := r_capacity + temp;
       
        
    END LOOP;

    IF (missing_instructor = TRUE) THEN
        RAISE EXCEPTION 'Offering does not have enough instructors for sessions';
    END IF;

    /*Inserting into course offering*/
    INSERT INTO CourseOfferings
    (offering_launch_date, offering_fees, offering_registration_deadline, offering_num_target_registration, offering_seating_capacity, course_id, admin_id, offering_start_date, offering_end_date)
    VALUES
    (launch_date, fees, registration_deadline, r_capacity, r_capacity, off_course_id, off_admin_id, off_start_date, off_end_date)
    RETURNING * INTO new_course_offering;
    offering_launch_date := new_course_offering.offering_launch_date;
    offering_fees := new_course_offering.offering_fees;
    offering_registration_deadline := new_course_offering.offering_registration_deadline;
    offering_num_target_registration := new_course_offering.offering_num_target_registration;
    offering_seating_capacity := new_course_offering.offering_seating_capacity;
    course_id := new_course_offering.course_id;
    admin_id := new_course_offering.admin_id;
    offering_start_date := new_course_offering.offering_start_date;
    offering_end_date := new_course_offering.offering_end_date;

    RETURN NEXT;

    /*Inserting Sessions*/
    FOR counter in 1..num_sessions 
        
    LOOP
        session_end_hour := sessions_arr[counter].session_start_hour + course_duration;
        PERFORM (SELECT add_session(off_course_id,launch_date,counter,sessions_arr[counter].session_date,sessions_arr[counter].session_start_hour,session_end_hour,instructor_id,sessions_arr[counter].room_id));
    END LOOP;

   
END;
$$ LANGUAGE plpgsql;
