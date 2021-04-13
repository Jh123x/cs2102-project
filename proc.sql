DROP FUNCTION IF EXISTS check_course_package CASCADE;
CREATE OR REPLACE FUNCTION check_course_package() RETURNS TRIGGER AS $$
DECLARE
    sale_start DATE;
    sale_end DATE;
    buy_date DATE := (SELECT NEW.buy_timestamp ::DATE);
BEGIN

    /*Get the sale start and end date*/
    SELECT package_sale_start_date, package_sale_end_date INTO sale_start, sale_end FROM CoursePackages cp
    WHERE cp.package_id = NEW.package_id;


    IF NOT (buy_date BETWEEN sale_start AND sale_end) THEN
        RAISE EXCEPTION 'Course package sale date has passed';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;
DROP TRIGGER IF EXISTS check_course_package_trigger ON Buys CASCADE;
CREATE TRIGGER check_course_package_trigger
BEFORE INSERT ON Buys
FOR EACH ROW EXECUTE FUNCTION check_course_package();

DROP FUNCTION IF EXISTS get_credit_card_expiry CASCADE;
CREATE OR REPLACE FUNCTION get_credit_card_expiry (
    credit_card_number_arg CHAR(16)
) RETURNS DATE AS $$
DECLARE
    expiry_date DATE;
BEGIN
    SELECT cc.credit_card_expiry_date INTO expiry_date
    FROM CreditCards cc
    WHERE cc.credit_card_number = credit_card_number_arg;
    
    RETURN expiry_date;
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS credit_card_expiry_check CASCADE;
CREATE OR REPLACE FUNCTION credit_card_expiry_check()
RETURNS TRIGGER AS $$
DECLARE
    table_lower_name TEXT;
BEGIN
    table_lower_name := LOWER(TG_TABLE_NAME);

    CASE
        WHEN table_lower_name = 'creditcards' THEN
            IF (NEW.credit_card_expiry_date < CURRENT_DATE) THEN
                RAISE EXCEPTION 'Cannot insert new credit card which already expired.';
            END IF;
        WHEN table_lower_name = 'owns' THEN
            IF get_credit_card_expiry(NEW.credit_card_number) < NEW.own_from_timestamp::DATE THEN
                RAISE EXCEPTION 'Cannot start owning a credit card which already expired.';
            END IF;
        WHEN table_lower_name ='buys' THEN
            IF get_credit_card_expiry(NEW.credit_card_number) < NEW.buy_timestamp::DATE THEN
                RAISE EXCEPTION 'Cannot buy course package using a credit card which already expired.';
            END IF;
        WHEN table_lower_name = 'registers' THEN
            IF get_credit_card_expiry(NEW.credit_card_number) < NEW.register_timestamp::DATE THEN
                RAISE EXCEPTION 'Cannot register for a course session using a credit card which already expired.';
            END IF;
        ELSE
            RAISE EXCEPTION 'Trigger is not suppose to be applied on table %', TG_TABLE_NAME;
        END CASE;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS credit_card_expiry ON CreditCards;
CREATE TRIGGER credit_card_expiry
AFTER INSERT OR UPDATE ON CreditCards
FOR EACH ROW EXECUTE FUNCTION credit_card_expiry_check();

DROP TRIGGER IF EXISTS credit_card_expiry ON Owns;
CREATE TRIGGER credit_card_expiry
AFTER INSERT OR UPDATE ON Owns
FOR EACH ROW EXECUTE FUNCTION credit_card_expiry_check();

DROP TRIGGER IF EXISTS credit_card_expiry ON Buys;
CREATE TRIGGER credit_card_expiry
AFTER INSERT OR UPDATE ON Buys
FOR EACH ROW EXECUTE FUNCTION credit_card_expiry_check();

DROP TRIGGER IF EXISTS credit_card_expiry ON Registers;
CREATE TRIGGER credit_card_expiry
AFTER INSERT OR UPDATE ON Registers
FOR EACH ROW EXECUTE FUNCTION credit_card_expiry_check();

CREATE OR REPLACE FUNCTION customer_cancels_check() RETURNS TRIGGER AS $$
DECLARE
    course_deadline DATE;
BEGIN
    /*Check if it is a package or not. Must be 1 or another and not both*/
    IF (NEW.cancel_refund_amount > 0 AND NEW.cancel_package_credit > 0) THEN
        RAISE EXCEPTION 'Either cancel_refund_amount or cancel_package_credit must be 0';
    END IF;

    IF (TG_OP = 'UPDATE' AND NEW.customer_id = OLD.customer_id) THEN
        return NEW;
    END IF;

    /*Get the date*/
    SELECT session_date INTO course_deadline FROM Sessions s
    WHERE s.course_id = NEW.course_id
    AND s.offering_launch_date = NEW.offering_launch_date
    AND s.session_id = NEW.session_id;


    IF (NEW.cancel_timestamp >= course_deadline + INTEGER '7' AND (NEW.cancel_refund_amount > 0 OR NEW.cancel_package_credit > 0) ) THEN
        RAISE EXCEPTION 'Refunds closer than 7 days are not eligible for refund';
    END IF;

    IF (NOT EXISTS(
        SELECT 1 FROM Registers r
        WHERE r.customer_id = NEW.customer_id
        AND r.course_id = NEW.course_id
        AND r.offering_launch_date = NEW.offering_launch_date
    ) AND NOT EXISTS(
        SELECT 1 FROM Redeems r
        WHERE r.course_id = NEW.course_id
        AND r.offering_launch_date = NEW.offering_launch_date
        AND r.session_id = NEW.session_id
    )) THEN 
        RAISE EXCEPTION 'Customer did not register for the course';
    END IF;

    return NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER customer_cancels_trigger
BEFORE INSERT OR UPDATE ON Cancels
FOR EACH ROW EXECUTE FUNCTION customer_cancels_check();

DROP FUNCTION IF EXISTS customer_redeems_check CASCADE;
CREATE OR REPLACE FUNCTION customer_redeems_check()
RETURNS TRIGGER AS $$
DECLARE
    num_remaining_redemptions INTEGER;
BEGIN
    SELECT COALESCE(SUM(buy_num_remaining_redemptions),0) INTO num_remaining_redemptions
    FROM Buys
    WHERE NEW.buy_timestamp = buy_timestamp;

    IF (num_remaining_redemptions < 0) THEN
        RAISE EXCEPTION 'There are no redemptions left for this customer';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER customer_redemption_trigger
BEFORE INSERT ON Redeems
FOR EACH ROW EXECUTE FUNCTION customer_redeems_check();

CREATE OR REPLACE FUNCTION check_offering_dates()
RETURNS TRIGGER AS $$
DECLARE
    m_start_date DATE;
    m_end_date DATE;
    c_course_id INTEGER;
    c_session_id INTEGER;
    c_offering_launch_date DATE;
    c_sessions INTEGER;
BEGIN

    SELECT COALESCE(NEW.course_id, OLD.course_id), COALESCE(NEW.session_id, OLD.session_id), COALESCE(NEW.offering_launch_date, OLD.offering_launch_date)
    INTO c_course_id, c_session_id, c_offering_launch_date;

    SELECT MAX(s.session_date), MIN(s.session_date) INTO m_end_date, m_start_date
    FROM Sessions s
    WHERE c_course_id = s.course_id
    AND c_offering_launch_date = s.offering_launch_date;

    IF m_end_date IS NULL OR m_start_date IS NULL THEN
        RAISE EXCEPTION 'There is 0 sessions left in the table after the operation';
    END IF;

    UPDATE CourseOfferings c
    SET offering_start_date = m_start_date,
        offering_end_date = m_end_date
    WHERE c.course_id = c_course_id
        AND c.offering_launch_date = c_offering_launch_date;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_date_trigger
AFTER INSERT OR DELETE OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION check_offering_dates();

/*
    Triggers for Customers Table:
    - Total Participation
*/

CREATE OR REPLACE FUNCTION customers_total_participation_check()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS(SELECT customer_id FROM Customers EXCEPT SELECT customer_id FROM Owns)
    THEN
        RAISE EXCEPTION 'Total participation constraint violated on Customers.customer_id -- customer_id should exist in at least one record of Owns relation.';
        ROLLBACK;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS customers_total_participation ON Customers;
CREATE CONSTRAINT TRIGGER customers_total_participation
AFTER INSERT OR UPDATE OR DELETE ON Customers
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION customers_total_participation_check();

/*
    Triggers for CreditCards Table:
    - Total Participation
    - Key Constraint
*/

CREATE OR REPLACE FUNCTION credit_cards_key_constraint_check()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS(SELECT credit_card_number FROM Owns GROUP BY credit_card_number HAVING COUNT(credit_card_number) > 1)
    THEN
        RAISE EXCEPTION 'Key constraint violated on CreditCards.credit_card_number -- credit_card_number should exist in at most one record of Owns relation.';
        ROLLBACK;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS credit_cards_key_constraint ON CreditCards;
CREATE CONSTRAINT TRIGGER credit_cards_key_constraint
AFTER INSERT OR UPDATE OR DELETE ON CreditCards
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION credit_cards_key_constraint_check();

CREATE OR REPLACE FUNCTION credit_cards_total_participation_check()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS(SELECT credit_card_number FROM CreditCards EXCEPT SELECT credit_card_number FROM Owns)
    THEN
        RAISE EXCEPTION 'Total participation constraint violated on CreditCards.credit_card_number -- credit_card_number should exist in at least one record of Owns relation.';
        ROLLBACK;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS credit_cards_total_participation ON CreditCards;
CREATE CONSTRAINT TRIGGER credit_cards_total_participation_constraint
AFTER INSERT OR UPDATE OR DELETE ON CreditCards
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION credit_cards_total_participation_check();

/*
    Triggers for Owns Table:
    - Total Participation (Customers)
    - Total Participation (CreditCards)
    - Key Constraint (CreditCards)
*/

DROP TRIGGER IF EXISTS customers_total_participation ON Owns;
CREATE CONSTRAINT TRIGGER customers_total_participation_constraint
AFTER INSERT OR UPDATE OR DELETE ON Owns
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION customers_total_participation_check();

DROP TRIGGER IF EXISTS credit_cards_key_constraint ON Owns;
CREATE CONSTRAINT TRIGGER credit_cards_key_constraint
AFTER INSERT OR UPDATE OR DELETE ON Owns
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION credit_cards_key_constraint_check();

/*
    -- Test case
    BEGIN TRANSACTION;

    TRUNCATE Customers CASCADE;
    TRUNCATE CreditCards CASCADE;

    INSERT INTO Customers (customer_id, customer_phone, customer_address, customer_name, customer_email) VALUES (1, 1, 'a', 'b', 'a@b.com');
    INSERT INTO CreditCards (credit_card_number, credit_card_cvv, credit_card_expiry_date) VALUES ('1234567890123456', '123', CURRENT_DATE);
    INSERT INTO Owns (customer_id, credit_card_number, own_from_timestamp) VALUES ('1', '1234567890123456', CURRENT_DATE);

    INSERT INTO Customers (customer_id, customer_phone, customer_address, customer_name, customer_email) VALUES (2, 1, 'a', 'b', 'a@b.com');
    INSERT INTO CreditCards (credit_card_number, credit_card_cvv, credit_card_expiry_date) VALUES ('1234567890123457', '123', CURRENT_DATE);
    INSERT INTO Owns (customer_id, credit_card_number, own_from_timestamp) VALUES ('2', '1234567890123457', CURRENT_DATE);
    COMMIT;

    -- Below should fail
    INSERT INTO Owns (customer_id, credit_card_number, own_from_timestamp) VALUES ('1', '1234567890123457', CURRENT_DATE);
    UPDATE Owns Set customer_id = 1 WHERE customer_id = 2;
    DELETE FROM Owns;
*/

CREATE OR REPLACE FUNCTION customer_session_check()
RETURNS TRIGGER AS $$
DECLARE
    registration_deadline   DATE;
    register_count          INTEGER;
    redeem_count            INTEGER;
    cancel_count            INTEGER;
    new_cust_id             INTEGER;
    old_cust_id             INTEGER;
    curr_date               DATE;
BEGIN

    /*Join the tables to obtain the customer for redeems*/
    IF (TG_TABLE_NAME ILIKE 'Redeems') THEN
        SELECT b.customer_id INTO new_cust_id 
        FROM Redeems r
        JOIN Buys b
        ON r.buy_timestamp = b.buy_timestamp
        WHERE NEW.buy_timestamp = b.buy_timestamp
        LIMIT 1;
        SELECT b.customer_id INTO old_cust_id
        FROM Redeems r
        JOIN Buys b
        ON r.buy_timestamp = b.buy_timestamp
        WHERE NEW.buy_timestamp = b.buy_timestamp
        LIMIT 1;
        curr_date := NEW.redeem_timestamp;
    ELSE
        new_cust_id := NEW.customer_id;
        old_cust_id := OLD.customer_id;
        curr_date := NEW.register_timestamp;
    END IF;
    IF (TG_OP = 'UPDATE' AND new_cust_id = old_cust_id AND NEW.course_id = OLD.course_id) THEN
        RETURN NEW;
    END IF;

    SELECT c.offering_registration_deadline INTO registration_deadline
    FROM CourseOfferings c
    WHERE c.course_id = NEW.course_id AND c.offering_launch_date = NEW.offering_launch_date;

    IF curr_date > registration_deadline THEN
        RAISE EXCEPTION 'Registration deadline for this session is over.';
    END IF;

    SELECT COUNT(*) INTO register_count 
    FROM Registers 
    WHERE new_cust_id = customer_id 
    AND NEW.course_id = course_id;

    SELECT COUNT(*) INTO redeem_count 
    FROM Redeems r
    JOIN Buys b
    ON b.buy_timestamp = r.buy_timestamp
    WHERE NEW.course_id = course_id
    AND b.customer_id = new_cust_id;
    IF (register_count > 0 OR redeem_count > 0) THEN
        RAISE EXCEPTION 'Already registered for a session of this course';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER customer_redeems_trigger
BEFORE INSERT OR UPDATE ON Redeems
FOR EACH ROW EXECUTE FUNCTION customer_session_check();

CREATE TRIGGER customer_register_trigger
BEFORE INSERT OR UPDATE ON Registers
FOR EACH ROW EXECUTE FUNCTION customer_session_check();

/* Enforce non-overlap between admin, manager and instructors */
DROP FUNCTION IF EXISTS role_check CASCADE;
CREATE OR REPLACE FUNCTION role_check()
RETURNS TRIGGER AS $$
DECLARE
    new_employee_id INTEGER;
BEGIN
    IF EXISTS(
        SELECT employee_id FROM (
            SELECT instructor_id AS employee_id FROM Instructors
            UNION ALL
            SELECT admin_id AS employee_id FROM Administrators
            UNION ALL
            SELECT manager_id AS employee_id FROM Managers
        ) AS Employees
        GROUP BY employee_id
        HAVING COUNT(employee_id) > 1
    )
    THEN
        RAISE EXCEPTION 'There are employees with multiple roles after operation.';
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS admin_check_trigger ON Administrators;
CREATE CONSTRAINT TRIGGER admin_check_trigger
AFTER INSERT OR UPDATE ON Administrators
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION role_check();

DROP TRIGGER IF EXISTS manager_check_trigger ON Managers;
CREATE CONSTRAINT TRIGGER manager_check_trigger
AFTER INSERT OR UPDATE ON Managers
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION role_check();

DROP TRIGGER IF EXISTS instructor_check_trigger ON Instructors;
CREATE CONSTRAINT TRIGGER instructor_check_trigger
AFTER INSERT OR UPDATE ON Instructors
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION role_check();

/* Do not allow the removal of any employees */
CREATE OR REPLACE FUNCTION no_deletion_of_employees()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'No deleting of employees, use the function or set a depart date instead.';
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER no_delete_employee_trigger
BEFORE DELETE ON Employees
FOR EACH ROW EXECUTE FUNCTION no_deletion_of_employees();

CREATE OR REPLACE FUNCTION part_full_time_check()
RETURNS TRIGGER AS $$
BEGIN
    IF (
        (NEW.employee_id IN (SELECT employee_id FROM PartTimeEmployees)) AND 
        (NEW.employee_id IN (SELECT employee_id FROM FullTimeEmployees))
    )
    THEN
        RAISE EXCEPTION 'Employee already exists in part time or full time role';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS part_time_insert_trigger ON PartTimeEmployees;
DROP TRIGGER IF EXISTS full_time_insert_trigger ON FullTimeEmployees;

CREATE TRIGGER part_time_insert_trigger
AFTER INSERT OR UPDATE ON PartTimeEmployees
FOR EACH ROW EXECUTE FUNCTION part_full_time_check();

CREATE TRIGGER full_time_insert_trigger
AFTER INSERT OR UPDATE ON FullTimeEmployees
FOR EACH ROW EXECUTE FUNCTION part_full_time_check();

CREATE OR REPLACE FUNCTION part_time_hour_check()
RETURNS TRIGGER AS $$
DECLARE
    hours INTEGER;
BEGIN
    SELECT COALESCE(SUM(session_end_hour - session_start_hour), 0) INTO hours
    FROM Sessions
    WHERE instructor_id = NEW.instructor_id AND DATE_TRUNC('month', session_date) = DATE_TRUNC('month', NEW.session_date);

    IF (hours > 30) THEN
        RAISE EXCEPTION 'Part time Employee working too much';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER not_more_than_30_trigger
AFTER INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION part_time_hour_check();

/* Check if the customer purchased the package when */
/* inserting into redeems table */
CREATE OR REPLACE FUNCTION redeems_check()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COALESCE(SUM(buy_num_remaining_redemptions),0) FROM Buys WHERE buy_timestamp = NEW.buy_timestamp) < 0 THEN
        RAISE EXCEPTION 'THERE IS NOTHING LEFT TO REDEEM';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER redemption_check_trigger
BEFORE INSERT ON Redeems
FOR EACH ROW EXECUTE FUNCTION redeems_check();

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

/*Check that the sessions inserted are not before the offering start date or after the offering end date*/

CREATE OR REPLACE FUNCTION session_date_check() RETURNS TRIGGER
AS $$
DECLARE
    register_date DATE;
BEGIN
    SELECT c.offering_registration_deadline INTO register_date
    FROM CourseOfferings c
    WHERE c.course_id = NEW.course_id
    AND c.offering_launch_date = NEW.offering_launch_date;

    /*Data sql violates this check for some reason*/
    IF (CURRENT_DATE <= register_date) THEN
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'Session cannot be added after registration deadline';
    END IF;

END;
$$ LANGUAGE plpgsql;



DROP TRIGGER IF EXISTS session_date_check_trigger ON Sessions;
CREATE TRIGGER session_date_check_trigger
AFTER INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION session_date_check();

CREATE OR REPLACE FUNCTION session_duration_check() RETURNS TRIGGER
AS $$
DECLARE
    session_duration INTEGER;
BEGIN
    /* Check if the old time and date = new time and date */
    IF (TG_OP = 'UPDATE' AND NEW.session_date = OLD.session_date AND NEW.session_start_hour = OLD.session_start_hour) THEN
        RETURN NEW;
    /* Check if it is a valid operation */
    ELSIF (TG_OP NOT IN ('INSERT', 'UPDATE')) THEN
        RAISE EXCEPTION 'Trigger is not suppose to be enforces in other methods.';
    END IF;

    /* Finding the duration from the course */
    SELECT c.course_duration INTO session_duration
    FROM Courses c
    WHERE c.course_id = NEW.course_id;

    /*Data sql violates this check for some reason*/
    IF (NEW.session_end_hour - NEW.session_start_hour = session_duration) THEN
        RETURN NEW;
    ELSE
        RAISE EXCEPTION 'Duration of session does not match course duration';
    END IF;

END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS session_duration_check_trigger ON Sessions;
CREATE TRIGGER session_duration_check_trigger
AFTER INSERT OR UPDATE ON Sessions
FOR EACH ROW EXECUTE FUNCTION session_duration_check();
/*
    5. add_course: This routine is used to add a new course.
    The inputs to the routine include the following:
        course title,
        course description,
        course area, and
        duration.
    The course identifier is generated by the system.
*/
DROP FUNCTION IF EXISTS add_course CASCADE;
CREATE OR REPLACE FUNCTION add_course (
    course_title TEXT,
    course_description TEXT,
    course_area_name TEXT,
    course_duration INTEGER
)
RETURNS TABLE (course_id INTEGER) AS $$
DECLARE
    new_course RECORD;
BEGIN
    /* Check for NULLs in arguments */
    IF course_title IS NULL
        OR course_description IS NULL
        OR course_area_name IS NULL
        OR course_duration IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to add_course() cannot contain NULL values.';
    END IF;

    INSERT INTO Courses
    (course_title, course_description, course_duration, course_area_name)
    VALUES
    (course_title, course_description, course_duration, course_area_name)
    RETURNING * INTO new_course;

    course_id := new_course.course_id;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

/*
    10. add_course_offering: This routine is used to add a new offering of an existing course.
    The inputs to the routine include the following:
        course offering identifier,
        course identifier,
        course fees,
        launch date,
        registration deadline,
        target number of registrations,
        administrator's identifier,and
        information for each session (session date, session start hour, and room identifier).
    If the input course offering information is valid, the routine will assign instructors for the sessions.
    If a valid instructor assignment exists, the routine will perform the necessary updates to add the course offering;
        otherwise, the routine will abort the course offering addition.
    Note that the seating capacity of the course offering must be at least equal to the course offering's target number of registrations.
*/

DROP TYPE IF EXISTS session_information;
CREATE TYPE session_information AS (
    session_date DATE,
    session_start_hour INTEGER,
    room_id INTEGER
);

DROP FUNCTION IF EXISTS add_course_offering CASCADE;
CREATE OR REPLACE FUNCTION add_course_offering (
    offering_launch_date_arg DATE,
    offering_fees_arg DEC(64, 2),
    sessions_arr session_information ARRAY,
    offering_registration_deadline_arg DATE,
    offering_num_target_registration_arg INTEGER,
    course_id_arg INTEGER,
    admin_id_arg INTEGER
)
RETURNS TABLE(
    offering_launch_date DATE,
    offering_fees DEC(64,2),
    offering_registration_deadline DATE,
    offering_num_target_registration INTEGER,
    offering_seating_capacity INTEGER,
    course_id INTEGER,
    admin_id INTEGER,
    offering_start_date DATE,
    offering_end_date DATE
) AS $$
DECLARE
    off_start_date DATE;
    off_end_date DATE;
    session_end_hour INTEGER;
    num_sessions INTEGER;
    course_duration INTEGER;
    instructor_id INTEGER;
    final_offering_seating_capacity INTEGER;
    new_course_offering RECORD;
BEGIN
    /* Check for NULLs in arguments */
    IF offering_launch_date_arg IS NULL
        OR offering_fees_arg IS NULL
        OR sessions_arr IS NULL
        OR offering_registration_deadline_arg IS NULL
        OR course_id_arg IS NULL
        OR admin_id_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to add_course_offering() cannot contain NULL values.';
    END IF;

    /* Check if there is at least one session in the array */
    SELECT COUNT(*) INTO num_sessions FROM unnest(sessions_arr);
    IF (num_sessions < 1) THEN
        RAISE EXCEPTION 'There needs to to be at least 1 session';
    END IF;

    FOR counter in 1..num_sessions
    LOOP
        IF sessions_arr[counter].session_date IS NULL
            OR sessions_arr[counter].session_start_hour IS NULL
            OR sessions_arr[counter].room_id IS NULL
        THEN
            RAISE EXCEPTION 'Arguments (session details) to add_course_offering() cannot contain NULL values.';
        END IF;
    END LOOP;

    /* Extracting the start date and end date */
    SELECT MIN(session_date) INTO off_start_date FROM unnest(sessions_arr);
    SELECT MAX(session_date) INTO off_end_date FROM unnest(sessions_arr);

    SELECT c.course_duration INTO course_duration
    FROM Courses c
    WHERE course_id_arg = c.course_id;

    /* Checking the conditions of course offering */
    IF (offering_launch_date_arg > offering_registration_deadline_arg) THEN
        RAISE EXCEPTION 'Offering registration date cannot be earlier than launch date';
    ELSIF (offering_num_target_registration_arg < 0) THEN
        RAISE EXCEPTION 'Offering target registration should be more than or equal to 0';
    ELSIF (off_start_date > off_end_date) THEN
        RAISE EXCEPTION 'Offering end date cannot be earlier than start date';
    ELSIF (off_start_date < offering_registration_deadline_arg + INTEGER '10') THEN
        RAISE EXCEPTION 'Offering start date should be after at least 10 days registration deadline';
    END IF;

    /* Inserting into course offering */
    /* Temporarily setting num target registration and seating capacity as 0 to pass check constraints first */
    /* seating capacity of course offering is updated in add_session(). */
    /* num target registration is update after all the sessions are added. */
    INSERT INTO CourseOfferings
    (offering_launch_date, offering_fees, offering_registration_deadline, offering_num_target_registration, offering_seating_capacity, course_id, admin_id, offering_start_date, offering_end_date)
    VALUES
    (offering_launch_date_arg, offering_fees_arg, offering_registration_deadline_arg, 0, 0, course_id_arg, admin_id_arg, off_start_date, off_end_date);

    /* Check if there is instructor for each session and check for session constraints */
    FOR counter in 1..num_sessions
    LOOP
        SELECT employee_id INTO instructor_id
        FROM get_available_instructors(course_id_arg, sessions_arr[counter].session_date, sessions_arr[counter].session_date)
        LIMIT 1;

        IF (instructor_id IS NULL) THEN
            RAISE EXCEPTION 'Offering does not have enough instructors for sessions.';
        END IF;

        session_end_hour := sessions_arr[counter].session_start_hour + course_duration;

        IF (sessions_arr[counter].session_start_hour >= 9 AND sessions_arr[counter].session_start_hour < 12 AND session_end_hour > 12) OR (sessions_arr[counter].session_start_hour > 18 OR session_end_hour > 18 OR sessions_arr[counter].session_start_hour < 9)
        THEN
            RAISE EXCEPTION 'Session time is out of range.';
        ELSIF sessions_arr[counter].room_id NOT IN (
            SELECT rid
            FROM find_rooms(sessions_arr[counter].session_date, sessions_arr[counter].session_start_hour, course_duration)
        ) THEN
            RAISE EXCEPTION 'Room % in use.', sessions_arr[counter].room_id;
        END IF;

        IF counter <> (SELECT add_session(course_id_arg, offering_launch_date_arg, counter, sessions_arr[counter].session_date, sessions_arr[counter].session_start_hour, instructor_id, sessions_arr[counter].room_id))
        THEN
            RAISE EXCEPTION 'Failed to add session successfully.';
        END IF;
    END LOOP;

    SELECT co.offering_seating_capacity INTO final_offering_seating_capacity
    FROM CourseOfferings co
    WHERE co.offering_launch_date = offering_launch_date_arg
        AND co.course_id = course_id_arg;

    IF (final_offering_seating_capacity < offering_num_target_registration_arg) THEN
        RAISE EXCEPTION 'Capacity is less than target number of registration';
    END IF;

    /* Finally, update course offering to have the right offering_num_target_registration value after all sessions are added */
    UPDATE CourseOfferings co
    SET offering_num_target_registration = offering_num_target_registration_arg
    WHERE co.offering_launch_date = offering_launch_date_arg
        AND co.course_id = course_id_arg;

    SELECT * INTO new_course_offering
    FROM CourseOfferings co
    WHERE co.offering_launch_date = offering_launch_date_arg
        AND co.course_id = course_id_arg;

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
END;
$$ LANGUAGE plpgsql;

/*
    11. add_course_package: This routine is used to add a new course package for sale.
    The inputs to the routine include the following:
        package name,
        number of free course sessions,
        start and end date indicating the duration that the promotional package is available for sale, and
        the price of the package.
    The course package identifier is generated by the system.
    If the course package information is valid, the routine will perform the necessary updates to add the new course package.
*/
DROP FUNCTION IF EXISTS add_course_package CASCADE;
CREATE OR REPLACE FUNCTION add_course_package (
    package_name TEXT,
    package_num_free_registrations INTEGER,
    package_sale_start_date DATE,
    package_sale_end_date DATE,
    package_price DEC(65, 2)
)
RETURNS TABLE (package_id INTEGER) AS $$
DECLARE
    new_package RECORD;
BEGIN
    /* Check for NULLs in arguments */
    IF package_name IS NULL
        OR package_num_free_registrations IS NULL
        OR package_sale_start_date IS NULL
        OR package_sale_end_date IS NULL
        OR package_price IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to add_course_package() cannot contain NULL values.';
    END IF;

    IF package_sale_end_date < CURRENT_DATE
    THEN
        RAISE EXCEPTION 'Cannot add a course package which has sales end date that had already past.';
    END IF;

    INSERT INTO CoursePackages
    (package_sale_start_date, package_num_free_registrations, package_sale_end_date, package_name, package_price)
    VALUES
    (package_sale_start_date, package_num_free_registrations, package_sale_end_date, package_name, package_price)
    RETURNING * INTO new_package;

    package_id := new_package.package_id;

    RETURN NEXT;
END
$$ LANGUAGE plpgsql;

/*
    3. add_customer: This routine is used to add a new customer.
    The inputs to the routine include the following:
        name,
        home address,
        contact number,
        email address, and
        credit card details (credit card number, expiry date, CVV code).
    The customer identifier is generated by the system.
*/
DROP FUNCTION IF EXISTS add_customer CASCADE;
CREATE OR REPLACE FUNCTION add_customer (
    customer_name TEXT,
    customer_address TEXT,
    customer_phone INTEGER,
    customer_email TEXT,
    credit_card_number CHAR(16),
    credit_card_cvv CHAR(3),
    credit_card_expiry_date DATE
)
RETURNS TABLE (customer_id INTEGER) AS $$
DECLARE
    new_customer RECORD;
BEGIN
    /* Check for NULLs in arguments */
    IF customer_name IS NULL
        OR customer_address IS NULL
        OR customer_phone IS NULL
        OR customer_email IS NULL
        OR credit_card_number IS NULL
        OR credit_card_cvv IS NULL
        OR credit_card_expiry_date IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to add_customer() cannot contain NULL values.';
    END IF;

    /* Insert values into credit card */
    INSERT INTO CreditCards
    (credit_card_number, credit_card_cvv, credit_card_expiry_date)
    VALUES
    (credit_card_number, credit_card_cvv, credit_card_expiry_date);

    /* Insert customer values with auto generated id */
    INSERT INTO Customers 
    (customer_phone, customer_address, customer_name, customer_email)
    VALUES
    (customer_phone, customer_address, customer_name, customer_email)
    RETURNING * INTO new_customer;

    customer_id := new_customer.customer_id;

    /* Match the credit card into the owner */
    INSERT INTO Owns
    (customer_id, credit_card_number, own_from_timestamp)
    VALUES
    (customer_id, credit_card_number, CURRENT_DATE);

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

/*
    1.add_employee: This routine is used to add a new employee.
    The inputs to the routine include the following:
        name,
        home address,
        contact number,
        email address,
        salary information (i.e., monthly salary for a full-time employee or hourly rate for a part-time employee),
        date that the employee joined the company,
        the employee category (manager, administrator, or instructor), and
        a (possibly empty) set of course areas.
    If the new employee is a manager, the set of course areas refers to the areas that are managed by the manager.
    If the new employee is an instructor, the set of course areas refers to the instructor's specialization areas.
    The set of course areas must be empty if the new employee is a administrator; and
        non-empty, otherwise.
    The employee identifier is generated by the system.

    Design Notes:
        Course areas are created alongside the addition of a manager.
        An instructor cannot be added unless the course area already exists.
*/
DROP FUNCTION IF EXISTS add_employee CASCADE;
CREATE OR REPLACE FUNCTION add_employee (
    employee_name TEXT,
    employee_address TEXT,
    employee_phone TEXT,
    employee_email TEXT,
    employee_join_date DATE,
    employee_category TEXT, /* Manager / Admin / Instructor */
    employee_type TEXT, /* Full Time / Part Time */
    salary_amount DEC(64, 2), /* hourly_rate for part-time and monthly_salary for full-time */
    course_area_names TEXT[] DEFAULT '{}'
)
RETURNS TABLE (employee_id INTEGER) AS $$
DECLARE
    new_employee RECORD;
    course_area_name TEXT;
BEGIN
    /* Check for NULLs in arguments */
    IF employee_name IS NULL
        OR employee_address IS NULL
        OR employee_phone IS NULL
        OR employee_email IS NULL
        OR employee_join_date IS NULL
        OR employee_category IS NULL
        OR employee_type IS NULL
        OR salary_amount IS NULL
        OR course_area_names IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to add_employee() cannot contain NULL values.';
    END IF;

    /* Insert the employee in */
    INSERT INTO Employees
    (employee_name, employee_address, employee_phone, employee_email, employee_join_date)
    VALUES
    (employee_name, employee_address, employee_phone, employee_email, employee_join_date)
    RETURNING * INTO new_employee;

    employee_id := new_employee.employee_id;

    /* Add into part-time / full time */
    IF (employee_type ILIKE 'part-time') THEN
        INSERT INTO PartTimeEmployees (employee_id, employee_hourly_rate) VALUES (employee_id, salary_amount);
    ELSIF (employee_type ILIKE 'full-time') THEN
        INSERT INTO FullTimeEmployees (employee_id, employee_monthly_salary) VALUES (employee_id, salary_amount);
    ELSE
        RAISE EXCEPTION 'Employee Type must be either Full-Time/Part-Time.';
    END IF;

    /* Add into role specific table */
    IF (employee_category ILIKE 'Manager') THEN
        IF (employee_type NOT ILIKE 'full-time') THEN
            RAISE EXCEPTION 'Employee type for Manager must be Full-time.';
        END IF;

        INSERT INTO Managers (manager_id) VALUES (employee_id);

        /* Add them to the specified course area */
        FOREACH course_area_name IN ARRAY course_area_names
        LOOP
            INSERT INTO CourseAreas (course_area_name, manager_id) VALUES (course_area_name, employee_id);
        END LOOP;
    ELSIF (employee_category ILIKE 'Admin') THEN
        IF (employee_type NOT ILIKE 'full-time') THEN
            RAISE EXCEPTION 'Employee type for Administrator must be Full-time.';
        END IF;

        INSERT INTO Administrators (admin_id) VALUES (employee_id);

        IF (array_length(course_area_names, 1) > 0) THEN
            RAISE EXCEPTION 'Admin should not have course area';
        END IF;
    ELSIF (employee_category ILIKE 'Instructor') THEN
        INSERT INTO Instructors (instructor_id) VALUES (employee_id);

        IF (employee_type ILIKE 'part-time') THEN
            INSERT INTO PartTimeInstructors (instructor_id) VALUES (employee_id);
        ELSE
            INSERT INTO FullTimeInstructors (instructor_id) VALUES (employee_id);
        END IF;

        FOREACH course_area_name IN ARRAY course_area_names
        LOOP
            INSERT INTO Specializes (instructor_id, course_area_name) VALUES (employee_id, course_area_name);
        END LOOP;
    ELSE
        RAISE EXCEPTION 'Employee category must be either Manager/Admin/Instructor.';
    END IF;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

/*
    24. add_session: This routine is used to add a new session to a course offering.
    The inputs to the routine include the following:
        course offering identifier,
        new session number,
        new session day,
        new session start hour,
        instructor identifier for new session, and
        room identifier for new session.
    If the course offering's registration deadline has not passed and the the addition request is valid, the routine will process the request with the necessary updates.
*/
DROP FUNCTION IF EXISTS add_session CASCADE;
CREATE OR REPLACE FUNCTION add_session (
    session_course_id INTEGER,
    session_offering_launch_date DATE,
    session_number INTEGER,
    session_date DATE,
    session_start_hour INTEGER,
    session_instructor_id INTEGER,
    session_room_id INTEGER
)
RETURNS TABLE (session_id INTEGER) AS $$
DECLARE
    new_package RECORD;
    session_end_hour INTEGER;
    session_offering_registration_deadline DATE;
    session_duration INTEGER;
    new_room_seating_capacity INTEGER;
BEGIN
    /* Check for NULLs in arguments */
    IF session_course_id IS NULL
        OR session_offering_launch_date IS NULL
        OR session_number IS NULL
        OR session_date IS NULL
        OR session_start_hour IS NULL
        OR session_instructor_id IS NULL
        OR session_room_id IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to add_session() cannot contain NULL values.';
    ELSIF NOT EXISTS(SELECT instructor_id FROM Instructors i WHERE i.instructor_id = session_instructor_id)
    THEN
        RAISE EXCEPTION 'Instructor ID % does not exists.', session_instructor_id;
    END IF;

    SELECT r.room_seating_capacity INTO new_room_seating_capacity
    FROM Rooms r
    WHERE r.room_id = session_room_id;

    IF new_room_seating_capacity IS NULL
    THEN
        RAISE EXCEPTION 'Room ID % does not exists.', session_room_id;
    END IF;

    session_id := session_number;

    /* Get the end hour from the courses */
    SELECT session_start_hour + course_duration INTO session_end_hour FROM Courses
    WHERE course_id = session_course_id;

    IF EXISTS(
        SELECT s.session_id FROM Sessions s
        WHERE s.course_id = session_course_id
            AND s.offering_launch_date = session_offering_launch_date
            AND s.session_id = session_number
    )
    THEN
        RAISE EXCEPTION 'Session ID already exists for course offering.';
    END IF;

    SELECT offering_registration_deadline INTO session_offering_registration_deadline
    FROM CourseOfferings co
    WHERE co.offering_launch_date = session_offering_launch_date
        AND co.course_id = session_course_id;

    IF (CURRENT_DATE > session_offering_registration_deadline)
    THEN
        RAISE EXCEPTION 'Course registration deadline already passed.';
    END IF;

    SELECT course_duration INTO session_duration FROM Courses WHERE session_course_id = course_id;
    IF NOT EXISTS (SELECT rid FROM find_rooms(session_date, session_start_hour,session_duration ) WHERE rid = session_room_id)
    THEN 
        RAISE EXCEPTION 'Room % is in use', session_room_id;
    END IF;

    IF NOT EXISTS (SELECT employee_id FROM find_instructors(session_course_id,session_date,session_start_hour) WHERE employee_id = session_instructor_id)
    THEN
        RAISE EXCEPTION 'Instructor is not available';
    END IF;
    
    INSERT INTO Sessions
    (session_id, session_date, session_start_hour, session_end_hour, course_id, offering_launch_date, room_id, instructor_id)
    VALUES
    (session_number, session_date, session_start_hour, session_end_hour, session_course_id, session_offering_launch_date, session_room_id, session_instructor_id);

    UPDATE CourseOfferings co
    SET offering_seating_capacity = (offering_seating_capacity + new_room_seating_capacity)
    WHERE co.course_id = session_course_id
        AND co.offering_launch_date = session_offering_launch_date;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

/*
    13. buy_course_package: This routine is used when a customer requests to purchase a course package.
    The inputs to the routine include the customer and course package identifiers.
    If the purchase transaction is valid, the routine will process the purchase with the necessary updates (e.g., payment).
*/
DROP FUNCTION IF EXISTS buy_course_package CASCADE;
CREATE OR REPLACE FUNCTION buy_course_package (
    customer_id_arg         INTEGER,
    package_id_arg          INTEGER
) RETURNS TABLE (r_buy_timestamp TIMESTAMP) AS $$
DECLARE
    package_sale_start_date         DATE;
    package_sale_end_date           DATE;
    package_num_free_registrations  INTEGER;
    own_credit_card_number          CHAR(16);
BEGIN
    /* Check for NULLs in arguments */
    IF customer_id_arg IS NULL
        OR package_id_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to buy_course_package() cannot contain NULL values.';
    ELSIF NOT EXISTS(SELECT customer_id FROM Customers c WHERE c.customer_id = customer_id_arg)
    THEN
        RAISE EXCEPTION 'Customer ID % does not exist.', customer_id_arg;
    ELSIF NOT EXISTS(SELECT package_id FROM CoursePackages cp WHERE cp.package_id = package_id_arg) THEN
        RAISE EXCEPTION 'Package ID % does not exist.', package_id_arg;
    END IF;

    /* Select last owned credit card of customer */
    SELECT o.credit_card_number INTO own_credit_card_number
    FROM Owns o
    NATURAL JOIN CreditCards cc
    WHERE o.customer_id = customer_id_arg
        AND cc.credit_card_expiry_date >= CURRENT_DATE
    ORDER BY o.own_from_timestamp DESC
    LIMIT 1;

    IF own_credit_card_number IS NULL THEN
        RAISE EXCEPTION 'No valid credit card found for customer. Check if credit card for customer_id supplied (%) is valid (e.g. it has not expired).', customer_id_arg;
    END IF;

    /* Check if customer has an active/partially active package now */
    IF customer_has_active_ish_course_package(customer_id_arg) IS TRUE
    THEN
        RAISE EXCEPTION 'Customer % cannot purchase a course package as there is an active/partially active course package.', customer_id_arg;
    END IF;

    /* Check if course package is still for sale */
    SELECT cp.package_sale_start_date, cp.package_sale_end_date, cp.package_num_free_registrations
        INTO package_sale_start_date, package_sale_end_date, package_num_free_registrations
    FROM CoursePackages cp
    WHERE cp.package_id = package_id_arg;

    IF CURRENT_DATE < package_sale_start_date THEN
        RAISE EXCEPTION 'This package is not for sale yet.';
    ELSIF package_sale_end_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'This package is no longer for sale.';
    END IF;

    /* Do buying here with Credit Card number */
    INSERT INTO Buys
    (buy_timestamp, buy_num_remaining_redemptions, package_id, customer_id, credit_card_number)
    VALUES
    (statement_timestamp(), package_num_free_registrations, package_id_arg, customer_id_arg, own_credit_card_number);

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

/*
    20. cancel_registration: This routine is used when a customer requests to cancel a registered course session.
    The inputs to the routine include the following:
        customer identifier, and
        course offering identifier.
    If the cancellation request is valid, the routine will process the request with the necessary updates.
*/
DROP FUNCTION IF EXISTS cancel_registration CASCADE;
CREATE OR REPLACE FUNCTION cancel_registration (
    customer_id_arg             INTEGER,
    course_id_arg               INTEGER,
    offering_launch_date_arg    DATE
) RETURNS VOID
AS $$
DECLARE
    enroll_timestamp    TIMESTAMP;
    r_session_id        INTEGER;
    enrolment_table     TEXT;
    offering_fees       DEC(64, 2);
    session_date        DATE;
    refund_amt          DEC(64,2);
    package_credit      INTEGER;
    buy_timestamp_var   TIMESTAMP;
BEGIN
    /* Check for NULLs in arguments */
    IF customer_id_arg IS NULL
        OR course_id_arg IS NULL
        OR offering_launch_date_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to cancel_registration() cannot contain NULL values.';
    ELSIF NOT EXISTS(SELECT customer_id FROM Customers c WHERE c.customer_id = customer_id_arg)
    THEN
        RAISE EXCEPTION 'Customer ID % does not exist.', customer_id_arg;
    ELSIF NOT EXISTS(
        SELECT offering_launch_date FROM CourseOfferings co
        WHERE co.course_id = course_id_arg
            AND co.offering_launch_date = offering_launch_date_arg
    ) THEN
        RAISE EXCEPTION 'Course offering specified does not exist.';
    END IF;

    SELECT e.enroll_timestamp, e.session_id, e.table_name INTO enroll_timestamp, r_session_id, enrolment_table
    FROM Enrolment e
    WHERE e.customer_id = customer_id_arg
        AND e.course_id = course_id_arg
        AND e.offering_launch_date = offering_launch_date_arg;

    IF enroll_timestamp IS NULL THEN
        RAISE EXCEPTION 'Customer did not register for this course offering.';
    END IF;

    SELECT c.offering_fees, s.session_date INTO offering_fees, session_date
    FROM Sessions s NATURAL JOIN CourseOfferings c
    WHERE s.course_id = course_id_arg AND s.offering_launch_date = offering_launch_date_arg AND s.session_id = r_session_id;

    IF enrolment_table = 'registers' THEN
        UPDATE Registers r
        SET register_cancelled = true
        WHERE r.register_timestamp = enroll_timestamp;

        IF CURRENT_DATE <= session_date - interval '7 days' THEN
            refund_amt := 0.90 * offering_fees;
        ELSE
            refund_amt := 0;
        END IF;

        INSERT INTO Cancels
        (cancel_timestamp, cancel_refund_amount, cancel_package_credit, course_id, session_id, offering_launch_date, customer_id)
        VALUES
        (statement_timestamp(), refund_amt, NULL, course_id_arg, r_session_id, offering_launch_date_arg, customer_id_arg);
    ELSE
        UPDATE Redeems r
        SET redeem_cancelled = true
        WHERE r.redeem_timestamp = enroll_timestamp;

        IF CURRENT_DATE <= session_date - interval '7 days' THEN
            package_credit := 1;

            /* Refund the redeemed session by incrementing customer's Buys.num_remaining_redemptions */
            SELECT b.buy_timestamp INTO buy_timestamp_var
            FROM Redeems r
            NATURAL JOIN Buys b
            WHERE r.redeem_timestamp = enroll_timestamp
            LIMIT 1;

            UPDATE Buys
            SET buy_num_remaining_redemptions = (buy_num_remaining_redemptions + 1)
            WHERE buy_timestamp = buy_timestamp_var;
        ELSE
            package_credit := 0;
        END IF;

        INSERT INTO Cancels
        (cancel_timestamp, cancel_refund_amount, cancel_package_credit, course_id, session_id, offering_launch_date, customer_id)
        VALUES
        (statement_timestamp(), NULL, package_credit, course_id_arg, r_session_id, offering_launch_date_arg, customer_id_arg);
    END IF;
END;
$$ LANGUAGE plpgsql;

/*
    6. find_instructors: This routine is used to find all the instructors who could be assigned to teach a course session.
    The inputs to the routine include the following:
        course identifier,
        session date, and
        session start hour.
    The routine returns a table of records consisting of
        employee identifier and
        name.
*/
DROP FUNCTION IF EXISTS is_full_time_instructor CASCADE;
CREATE OR REPLACE FUNCTION is_full_time_instructor (instructor_id_arg INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(SELECT * FROM FullTimeInstructors i WHERE i.instructor_id = instructor_id_arg);
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS is_part_time_instructor CASCADE;
CREATE OR REPLACE FUNCTION is_part_time_instructor (instructor_id_arg INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(SELECT * FROM PartTimeInstructors i WHERE i.instructor_id = instructor_id_arg);
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS find_instructors CASCADE;
CREATE OR REPLACE FUNCTION find_instructors (
    course_id_arg INTEGER,
    session_date_arg DATE,
    session_start_hour_arg INTEGER
)
RETURNS TABLE (employee_id INTEGER, employee_name TEXT) AS $$
DECLARE
    session_end_hour_var INTEGER;
    new_session_duration INTEGER;
BEGIN
    /* Check for NULLs in arguments */
    IF course_id_arg IS NULL
        OR session_date_arg IS NULL
        OR session_start_hour_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to find_instructors() cannot contain NULL values.';
    END IF;

    /* Check if course_id supplied is valid */
    IF NOT EXISTS(
        SELECT c.course_id FROM Courses c
        WHERE c.course_id = course_id_arg
    ) THEN
        RAISE EXCEPTION 'Course ID not found.';
    END IF;
    /* Todo: Validate session_date and session_start_hour to ensure > current time? */
    /*Maybe do not need to enforce that because they didnt mention?*/

    /*Get the duration of the course*/
    SELECT course_duration, session_start_hour_arg + course_duration
    INTO new_session_duration, session_end_hour_var
    FROM Courses
    WHERE Courses.course_id = course_id_arg;

    /*
    * requirements:
    * - must be specialized in that area
    * - can only teach one session at any hour
    * - cannot teach two consecutuve sessions (i.e. must have at least one hour of break between any two course sessions)
    * - cannot teach a course that ends at session_start_hour)
    * - part time instructor must not teach more than 30 hours for each month
    */
    RETURN QUERY (
        SELECT DISTINCT e.employee_id, e.employee_name
        FROM Employees e
        JOIN Instructors i
        ON i.instructor_id = e.employee_id
        NATURAL JOIN Specializes sp
        WHERE e.employee_join_date <= session_date_arg /* Check for the hire date of the instructors */
            AND NOT EXISTS (
                SELECT 1
                FROM Sessions s
                WHERE (
                        s.session_date = session_date_arg
                        AND s.instructor_id = e.employee_id
                    )
                    AND
                    (
                        /* Check for overlap instead of just checking if start lands within */
                        (s.session_start_hour <= session_start_hour_arg AND session_start_hour_arg <= s.session_end_hour)
                        OR 
                        (session_start_hour_arg <= s.session_start_hour AND s.session_start_hour <= session_end_hour_var)
                        /* 1 hour break in between */
                        OR s.session_end_hour = session_start_hour_arg
                    )
            )
            AND (
                is_full_time_instructor(e.employee_id)
                OR (
                    is_part_time_instructor(e.employee_id)
                    AND (new_session_duration + (
                        SELECT COALESCE(SUM(session_end_hour - session_start_hour), 0)
                        FROM Sessions s
                        WHERE s.instructor_id = e.employee_id
                            AND DATE_TRUNC('month', session_date_arg) = DATE_TRUNC('month', CURRENT_DATE)
                    )) <= 30
                )
            )
            AND sp.course_area_name = (
                SELECT course_area_name
                FROM Courses
                WHERE course_id = course_id_arg
            )
    );
END;
$$ LANGUAGE plpgsql;

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
    r_session_date DATE,
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
            AND s.session_date = r_session_date
            AND (
                r_session_start_hour BETWEEN s.session_start_hour AND (s.session_end_hour - 1)
                OR
                s.session_start_hour BETWEEN r_session_start_hour AND (end_hour - 1)
            )
        ));
    rec RECORD;
BEGIN
    /* Check for NULLs in arguments */
    IF r_session_date IS NULL
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

/*
    15. get_available_course_offerings: This routine is used to retrieve all the available course offerings that could be registered.
    The routine returns a table of records with the following information for each course offering:
        course title,
        course area,
        start date,
        end date,
        registration deadline,
        course fees, and
        the number of remaining seats.
    The output is sorted in
        ascending order of registration deadline and
        course title.
*/
DROP FUNCTION IF EXISTS get_offering_num_remaining_seats CASCADE;
CREATE OR REPLACE FUNCTION get_offering_num_remaining_seats (
    offering_launch_date_arg DATE,
    course_id_arg INTEGER
) RETURNS INTEGER AS $$
DECLARE
    num_remaining_seats INTEGER;
BEGIN
    /* Check for NULLs in arguments */
    IF offering_launch_date_arg IS NULL
        OR course_id_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to get_offering_num_remaining_seats() cannot contain NULL values.';
    END IF;

    SELECT SUM(get_session_num_remaining_seats(s.session_id, s.offering_launch_date, s.course_id)) INTO num_remaining_seats
    FROM Sessions s
    WHERE s.offering_launch_date = offering_launch_date_arg
        AND s.course_id = course_id_arg;

    IF num_remaining_seats IS NULL
    THEN
        num_remaining_seats := 0;
    END IF;

    RETURN num_remaining_seats;
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS get_available_course_offerings CASCADE;
CREATE OR REPLACE FUNCTION get_available_course_offerings()
RETURNS TABLE(
    course_title TEXT,
    course_area_name TEXT,
    offering_start_date DATE,
    offering_end_date DATE,
    offering_registration_deadline DATE,
    offering_fees DEC(64,2),
    offering_num_remaining_seats INTEGER
) AS $$
BEGIN
    RETURN QUERY (
        SELECT 
            c.course_title,
            ca.course_area_name,
            co.offering_start_date,
            co.offering_end_date,
            co.offering_registration_deadline,
            co.offering_fees,
            get_offering_num_remaining_seats(co.offering_launch_date, co.course_id)
        FROM CourseOfferings co
        NATURAL JOIN Courses c
        NATURAL JOIN CourseAreas ca
        WHERE co.offering_registration_deadline >= CURRENT_DATE
            AND get_offering_num_remaining_seats(co.offering_launch_date, co.course_id) > 0
        ORDER BY co.offering_registration_deadline ASC, c.course_title ASC
    );

    IF NOT FOUND THEN
        RAISE NOTICE 'No course offerings are available for registration now.';
    END IF;
END;
$$ LANGUAGE PLPGSQL;

/*
    12. get_available_course_packages: This routine is used to retrieve the course packages that are available for sale.
    The routine returns a table of records with the following information for each available course package:
        package name,
        number of free course sessions,
        end date for promotional package, and
        the price of the package.
*/
DROP FUNCTION IF EXISTS get_available_course_packages CASCADE;
CREATE OR REPLACE FUNCTION get_available_course_packages()
RETURNS TABLE(
    package_name TEXT,
    package_num_free_registrations INTEGER,
    package_sale_end_date DATE,
    package_price DEC(64,2)
) AS $$
BEGIN

    RETURN QUERY (
        /*Might have duplicates*/
        SELECT DISTINCT cp.package_name, cp.package_num_free_registrations, cp.package_sale_end_date, cp.package_price
        FROM CoursePackages cp
        WHERE cp.package_sale_end_date >= CURRENT_DATE
    );

    IF NOT FOUND THEN
        RAISE NOTICE 'No course packages are on sale now.';
    END IF;
END;
$$ LANGUAGE PLPGSQL;

/*
    16. get_available_course_sessions: This routine is used to retrieve all the available sessions for a course offering that could be registered.
    The input to the routine is a course offering identifier.
    The routine returns a table of records with the following information for each available session:
        session date,
        session start hour,
        instructor name, and
        number of remaining seats for that session.
    The output is sorted in
        ascending order of session date and
        start hour.
*/
DROP FUNCTION IF EXISTS get_session_num_remaining_seats CASCADE;
CREATE OR REPLACE FUNCTION get_session_num_remaining_seats (
    session_id_arg INTEGER,
    offering_launch_date_arg DATE, 
    course_id_arg INTEGER
) RETURNS INTEGER AS $$
DECLARE
    num_remaining_seats INTEGER;
BEGIN
    /* Check for NULLs in arguments */
    IF session_id_arg IS NULL
        OR offering_launch_date_arg IS NULL
        OR course_id_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to get_session_num_remaining_seats() cannot contain NULL values.';
    END IF;

    WITH Registrations AS (
        SELECT COUNT(r.register_timestamp) AS num_registered
        FROM Registers r
        WHERE r.session_id = session_id_arg 
            AND r.offering_launch_date = offering_launch_date_arg 
            AND r.course_id = course_id_arg
            AND r.register_cancelled IS NOT TRUE
    ), Redemptions AS (
        SELECT COUNT(r.redeem_timestamp) AS num_redeemed
        FROM Redeems r
        WHERE r.session_id = session_id_arg 
            AND r.offering_launch_date = offering_launch_date_arg 
            AND r.course_id = course_id_arg
            AND r.redeem_cancelled IS NOT TRUE
    ), SessionRoom AS (
        SELECT r.room_seating_capacity AS room_seating_capacity
        FROM Sessions s
        NATURAL JOIN Rooms r
        WHERE s.session_id = session_id_arg 
            AND s.offering_launch_date = offering_launch_date_arg 
            AND s.course_id = course_id_arg
    )
    SELECT (room_seating_capacity - COALESCE(num_registered, 0) - COALESCE(num_redeemed, 0)) INTO num_remaining_seats
    FROM Registrations, Redemptions, SessionRoom;

    IF num_remaining_seats IS NULL
    THEN
        num_remaining_seats := 0;
    END IF;

    RETURN num_remaining_seats;
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS get_available_course_sessions CASCADE;
CREATE OR REPLACE FUNCTION get_available_course_sessions (
    offering_launch_date_arg DATE, 
    course_id_arg INTEGER
)
RETURNS TABLE(
    session_date DATE,
    session_start_hour INTEGER,
    instructor_name TEXT,
    session_num_remaining_seats INTEGER
) AS $$
BEGIN
    /* Check for NULLs in arguments */
    IF offering_launch_date_arg IS NULL
        OR course_id_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to get_available_course_sessions() cannot contain NULL values.';
    END IF;

    RETURN QUERY (
        SELECT 
            s.session_date,
            s.session_start_hour,
            e.employee_name,
            get_session_num_remaining_seats(s.session_id, offering_launch_date, course_id)
        FROM Sessions s
        NATURAL JOIN CourseOfferings co
        NATURAL JOIN Instructors i 
        INNER JOIN Employees e ON i.instructor_id = e.employee_id
        WHERE s.offering_launch_date = offering_launch_date_arg
            AND s.course_id = course_id_arg
            AND co.offering_registration_deadline >= CURRENT_DATE
            AND get_session_num_remaining_seats(s.session_id, offering_launch_date, course_id) > 0
        ORDER BY s.session_date ASC, s.session_start_hour ASC
    );

    IF NOT FOUND THEN
        RAISE NOTICE 'No course offerings are available for registration now.';
    END IF;
END;
$$ LANGUAGE PLPGSQL;

/*
    7. get_available_instructors: This routine is used to retrieve the availability information of instructors who could be assigned to teach a specified course.
    The inputs to the routine include the following:
        course identifier,
        start date, and
        end date.
    The routine returns a table of records consisting of the following information:
        employee identifier,
        name,
        total number of teaching hours that the instructor has been assigned for this month,
        day (which is within the input date range [start date, end date]), and
        an array of the available hours for the instructor on the specified day.
    The output is sorted in
        ascending order of employee identifier and
        day, and
        the array entries are sorted in
            ascending order of hour.
*/

DROP FUNCTION IF EXISTS get_available_instructors CASCADE;
CREATE OR REPLACE FUNCTION get_available_instructors (
    course_id_arg INTEGER,
    start_date_arg DATE,
    end_date_arg DATE
)
RETURNS TABLE (
    employee_id INTEGER,
    name TEXT,
    total_teaching_hours INTEGER,
    day DATE,
    available_hours INTEGER[]
) AS $$
DECLARE
    /*Remove duplicates in the query as it has alot of duplicates*/
    curs CURSOR FOR (
        SELECT DISTINCT e.employee_id, e.employee_name
        FROM Employees e
        NATURAL JOIN Specializes s
        NATURAL JOIN Courses c
        WHERE c.course_id = course_id_arg
        AND e.employee_join_date <= start_date_arg /*Check if the instructor has already been hired*/
        ORDER BY e.employee_id ASC
    );
    r RECORD;
    cur_date DATE;
    hour INTEGER;
    work_hours INTEGER[] := ARRAY[9,10,11,14,15,16,17];

BEGIN
    /* Check for NULLs in arguments */
    IF course_id_arg IS NULL
        OR start_date_arg IS NULL
        OR end_date_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to get_available_instructors() cannot contain NULL values.';
    ELSIF start_date_arg > end_date_arg THEN
        RAISE EXCEPTION 'Start date should not be later than end date.';
    END IF;

    OPEN curs;
    LOOP
        FETCH curs INTO r;
        EXIT WHEN NOT FOUND;

        cur_date := start_date_arg;
        LOOP
            EXIT WHEN cur_date > end_date_arg;

            day := cur_date;
            employee_id := r.employee_id;
            name := r.employee_name;
            available_hours := '{}';

            /* requirement: total number of teaching hours that the instructor has been assigned for this month */
            /* assuming that this month refers to the day in this row */
            SELECT COALESCE(SUM(s.session_end_hour - s.session_start_hour), 0) INTO total_teaching_hours
            FROM Sessions s
                WHERE s.instructor_id = r.employee_id
                    AND DATE_TRUNC('month', s.session_date) = DATE_TRUNC('month', cur_date);

            FOREACH hour IN ARRAY work_hours LOOP
                IF employee_id IN
                    (SELECT i.employee_id FROM find_instructors(course_id_arg, cur_date, hour) i) THEN
                    available_hours := array_append(available_hours, hour);
                END IF;
            END LOOP;

            IF array_length(available_hours, 1) > 0 THEN
                RETURN NEXT;
            END IF;

            cur_date := cur_date + interval '1 day';
        END LOOP;
    END LOOP;
    CLOSE curs;
END;
$$ LANGUAGE plpgsql;

/*
    9. get_available_rooms: This routine is used to retrieve the availability information of rooms for a specific duration.
    The inputs to the routine include
        a start date and
        an end date.
    The routine returns a table of records consisting of the following information:
        room identifier,
        room capacity,
        day (which is within the input date range [start date, end date]),
        and an array of the hours that the room is available on the specified day.
    The output is sorted in ascending order of room identifier and day,
        and the array entries are sorted in ascending order of hour.
*/
DROP FUNCTION IF EXISTS get_available_rooms CASCADE;
CREATE OR REPLACE FUNCTION get_available_rooms (
    start_date DATE,
    end_date DATE
)
RETURNS TABLE (
    room_id                 INTEGER,
    room_seating_capacity   INTEGER,
    day                     DATE,
    available_hours         INTEGER[]
) AS $$
DECLARE
    curs CURSOR FOR (
        SELECT r.room_id, r.room_seating_capacity
        FROM Rooms r
    ) ORDER BY r.room_id ASC;
    r RECORD;

    cur_date DATE;
    cur_hour INTEGER;
    /* Rooms can only be used from 9am - 12pm and 2pm - 6pm. */
    start_hours INTEGER[] := ARRAY[9,10,11,14,15,16,17];
BEGIN
    /* Check for NULLs in arguments */
    IF start_date IS NULL OR end_date IS NULL THEN
        RAISE EXCEPTION 'Start and end dates cannot be NULL.';
    ELSIF start_date > end_date THEN
        RAISE EXCEPTION 'Start date cannot be later than end date.';
    END IF;

    OPEN curs;
    LOOP
        FETCH curs INTO r;
        EXIT WHEN NOT FOUND;

        cur_date := start_date;
        LOOP
            EXIT WHEN cur_date > end_date;

            room_id := r.room_id;
            room_seating_capacity := r.room_seating_capacity;
            day := cur_date;
            available_hours := '{}'; /* need to reset to empty array for each room-day pair */

            FOREACH cur_hour IN ARRAY start_hours LOOP
                /* Check room availability for 1 hour block on current iterated date */
                IF room_id IN (SELECT rid FROM find_rooms(cur_date, cur_hour, 1))
                THEN
                    available_hours := array_append(available_hours, cur_hour);
                END IF;
            END LOOP;

            /* Only include into results if room is free for at least one hour on the current iterated date */
            IF array_length(available_hours, 1) > 0 THEN
                RETURN NEXT;
            END IF;

            cur_date := cur_date + INTERVAL '1 day';
        END LOOP;
    END LOOP;
    CLOSE curs;
END;
$$ LANGUAGE plpgsql;

/*
    14. get_my_course_package: This routine is used when a customer requests to view his/her active/partially active course package.
    The input to the routine is a customer identifier.
    The routine returns the following information as a JSON value:
        package name,
        purchase date,
        price of package,
        number of free sessions included in the package,
        number of sessions that have not been redeemed, and
        information for each redeemed session (course name, session date, session start hour).
    The redeemed session information is sorted in
        ascending order of session date and
        start hour.
*/
DROP FUNCTION IF EXISTS customer_has_active_ish_course_package CASCADE;
CREATE OR REPLACE FUNCTION customer_has_active_ish_course_package (
    customer_id_arg INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT * FROM get_customer_active_ish_course_package(customer_id_arg) AS cp
    );
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS get_customer_active_ish_course_package CASCADE;
CREATE OR REPLACE FUNCTION get_customer_active_ish_course_package (
    customer_id_arg INTEGER
)
RETURNS TABLE(
    buy_timestamp TIMESTAMP,
    package_name TEXT,
    package_price DEC(64,2),
    package_num_free_registrations INTEGER,
    buy_num_remaining_redemptions INTEGER
) AS $$
BEGIN
    RETURN QUERY (
        /*
            Active - at least one unused session in the package
            Partially active - at least one cancellable session (at least 7 days before session date)
        */
        SELECT cp.buy_timestamp, cp.package_name, cp.package_price, cp.package_num_free_registrations, cp.buy_num_remaining_redemptions
        FROM get_customer_course_packages(customer_id_arg) AS cp
        WHERE cp.buy_num_remaining_redemptions > 1
            OR EXISTS(
                SELECT redeem_timestamp
                FROM Redeems r
                NATURAL JOIN Buys b
                NATURAL JOIN Sessions s
                WHERE r.buy_timestamp = cp.buy_timestamp AND s.session_date >= CURRENT_DATE + 7
            )
        ORDER BY cp.buy_timestamp DESC
        LIMIT 1
    );
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS customer_has_course_packages CASCADE;
CREATE OR REPLACE FUNCTION customer_has_course_packages (
    customer_id_arg INTEGER
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(
        SELECT * FROM get_customer_course_packages(customer_id_arg) AS cp
    );
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS get_customer_course_packages CASCADE;
CREATE OR REPLACE FUNCTION get_customer_course_packages (
    customer_id_arg INTEGER
)
RETURNS TABLE(
    buy_timestamp TIMESTAMP,
    package_name TEXT,
    package_price DEC(64,2),
    package_num_free_registrations INTEGER,
    buy_num_remaining_redemptions INTEGER
) AS $$
BEGIN
    RETURN QUERY (
        SELECT b.buy_timestamp, cp.package_name, cp.package_price, cp.package_num_free_registrations, b.buy_num_remaining_redemptions
        FROM Buys b
        NATURAL JOIN CoursePackages cp
        WHERE b.customer_id = customer_id_arg
        ORDER BY buy_timestamp DESC
    );
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS get_my_course_package CASCADE;
CREATE OR REPLACE FUNCTION get_my_course_package (
    customer_id_arg INTEGER
)
RETURNS TABLE(course_package_details JSON) AS $$
DECLARE
    cp_buy_timestamp TIMESTAMP;
    package_name TEXT;
    package_price DEC(64,2);
    package_num_free_registrations INTEGER;
    buy_num_remaining_redemptions INTEGER;
    redeemed_sessions JSON;
BEGIN
    /* Check for NULLs in arguments */
    IF customer_id_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to get_my_course_package() cannot contain NULL values.';
    END IF;

    IF NOT EXISTS(SELECT customer_id FROM Customers c WHERE c.customer_id = customer_id_arg)
    THEN
        RAISE EXCEPTION 'Customer ID % does not exist.', customer_id_arg;
    END IF;

    IF customer_has_course_packages(customer_id_arg) IS NOT TRUE
    THEN
        RAISE NOTICE 'Customer % has not purchased any course packages.', customer_id_arg;
        course_package_details := row_to_json(row());
    ELSIF customer_has_active_ish_course_package(customer_id_arg) IS NOT TRUE
    THEN
        RAISE NOTICE 'Customer % has no active or partially active course packages.', customer_id_arg;
        course_package_details := row_to_json(row());
    ELSE
        /* Customer must have either active or partially active course package */
        SELECT cp.buy_timestamp, cp.package_name, cp.package_price, cp.package_num_free_registrations, cp.buy_num_remaining_redemptions
        INTO cp_buy_timestamp, package_name, package_price, package_num_free_registrations, buy_num_remaining_redemptions
        FROM get_customer_active_ish_course_package(customer_id_arg) AS cp;

        /* Aggregate all sessions redeemed using course package sorted in ascending order of session date and start hour */
        SELECT COALESCE(json_agg(session_information), '[]'::JSON) INTO redeemed_sessions
        FROM (
            SELECT c.course_title, s.session_date, s.session_start_hour
            FROM Redeems r
            NATURAL JOIN Buys b
            NATURAL JOIN Sessions s
            NATURAL JOIN CourseOfferings co
            NATURAL JOIN Courses c
            WHERE r.buy_timestamp = cp_buy_timestamp AND r.redeem_cancelled IS NOT TRUE
            ORDER BY s.session_date ASC, s.session_start_hour ASC
        ) AS session_information;

        /* Return value is JSON object */
        SELECT jsonb_build_object(
            'buy_timestamp', cp_buy_timestamp,
            'package_name', package_name,
            'package_price', package_price,
            'package_num_free_registrations', package_num_free_registrations,
            'buy_num_remaining_redemptions', buy_num_remaining_redemptions,
            'redeemed_sessions', redeemed_sessions
        ) INTO course_package_details;
    END IF;
    RETURN NEXT;
END;
$$ LANGUAGE PLPGSQL;

/*
    18. get_my_registrations: This routine is used when a customer requests to view his/her active course registrations (i.e, registrations for course sessions that have not ended).
    The input to the routine is a customer identifier.
    The routine returns a table of records with the following information for each active registration session:
        course name,
        course fees,
        session date,
        session start hour,
        session duration, and
        instructor name.
    The output is sorted in
        ascending order of session date and
        session start hour.
*/
DROP FUNCTION IF EXISTS get_my_registrations CASCADE;
CREATE OR REPLACE FUNCTION get_my_registrations (
    r_customer_id INTEGER
)
RETURNS TABLE(
    course_title TEXT,
    offering_fees DEC(64,2),
    session_date DATE,
    session_start_hour INTEGER,
    course_duration INTEGER,
    instructor_name TEXT
) AS $$
BEGIN
    /* Check for NULLs in arguments */
    IF r_customer_id IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to get_my_registrations() cannot contain NULL values.';
    END IF;

    IF NOT EXISTS(SELECT customer_id FROM Customers c WHERE c.customer_id = r_customer_id)
    THEN
        RAISE EXCEPTION 'Customer ID % does not exist.', r_customer_id;
    END IF;

    RETURN QUERY (
        WITH CourseRegistrations(session_id, offering_launch_date, course_id) AS (
            SELECT Registers.session_id, Registers.offering_launch_date, Registers.course_id
            FROM Registers
            WHERE Registers.customer_id = r_customer_id AND Registers.register_cancelled IS NOT TRUE
            UNION
            SELECT r.session_id, r.offering_launch_date, r.course_id
            FROM Redeems r
            JOIN Buys b
            ON b.buy_timestamp = r.buy_timestamp
            WHERE b.customer_id = r_customer_id AND r.redeem_cancelled IS NOT TRUE
        ) 
        SELECT
            c.course_title,
            co.offering_fees,
            s.session_date,
            s.session_start_hour,
            c.course_duration,
            e.employee_name
        FROM CourseRegistrations
        NATURAL JOIN Sessions s
        NATURAL JOIN CourseOfferings co
        NATURAL JOIN Courses c
        INNER JOIN Employees e ON s.instructor_id = e.employee_id
        WHERE s.session_date >= CURRENT_DATE
            /* If current hour is session_end_hour, we consider the session to have ended. */
            AND s.session_end_hour > EXTRACT(HOUR FROM CURRENT_TIMESTAMP)
        ORDER BY s.session_date ASC, s.session_start_hour ASC
    );

    IF NOT FOUND THEN
        RAISE NOTICE 'No active course registrations found for customer %.', r_customer_id;
    END IF;
END;
$$ LANGUAGE PLPGSQL;

/*
    25. pay_salary: This routine is used at the end of the month to pay salaries to employees.
    The routine inserts the new salary payment records and
        returns a table of records
        (sorted in ascending order of employee identifier)
        with the following information for each employee who is paid for the month:
            employee identifier,
            name,
            status (either part-time or full-time),
            number of work days for the month,
            number of work hours for the month,
            hourly rate,
            monthly salary, and
            salary amount paid.
    For a part-time employees, the values for number of work days for the month and monthly salary should be null.
    For a full-time employees, the values for number of work hours for the month and hourly rate should be null.
*/
DROP FUNCTION IF EXISTS pay_salary CASCADE;
CREATE OR REPLACE FUNCTION pay_salary()
RETURNS TABLE (
    employee_id INTEGER,
    name TEXT,
    status TEXT,
    num_work_days INTEGER,
    num_work_hours INTEGER,
    hourly_rate NUMERIC,
    monthly_salary NUMERIC,
    amount_paid NUMERIC
) AS $$
DECLARE
    curs_part_time CURSOR FOR (
        SELECT * FROM PartTimeEmployees NATURAL JOIN Employees
    );
    curs_full_time CURSOR FOR (
        SELECT * FROM FullTimeEmployees NATURAL JOIN Employees e
        WHERE e.employee_depart_date IS NULL OR e.employee_depart_date >= DATE_TRUNC('month', NOW())
    );
    r RECORD;

    first_work_day INTEGER;
    last_work_day INTEGER;
    num_days_in_month INTEGER;
BEGIN
    OPEN curs_part_time;
    LOOP
        FETCH curs_part_time INTO r;
        EXIT WHEN NOT FOUND;

        employee_id := r.employee_id;
        name := r.employee_name;
        status := 'part-time';
        num_work_days := NULL;

        SELECT COALESCE(SUM(session_end_hour - session_start_hour), 0) INTO num_work_hours
        FROM Sessions s
        WHERE r.employee_id = s.instructor_id AND DATE_TRUNC('month', s.session_date) = DATE_TRUNC('month', CURRENT_DATE);

        hourly_rate := r.employee_hourly_rate;
        monthly_salary := NULL;

        amount_paid := hourly_rate * num_work_hours;

        INSERT INTO PaySlips(employee_id, payslip_date, payslip_amount, payslip_num_work_hours, payslip_num_work_days)
        VALUES (employee_id, CURRENT_DATE, amount_paid, num_work_hours, num_work_days);
        RETURN NEXT;
    END LOOP;
    CLOSE curs_part_time;

    OPEN curs_full_time;
    LOOP
        FETCH curs_full_time INTO r;
        EXIT WHEN NOT FOUND;

        employee_id := r.employee_id;
        name := r.employee_name;
        status := 'full-time';
        num_work_hours := NULL;

        num_days_in_month := EXTRACT(days FROM DATE_TRUNC('month', NOW()) + interval '1 month - 1 day');
        IF r.employee_join_date < DATE_TRUNC('month', NOW()) THEN
            first_work_day := 1;
        ELSE
            first_work_day := EXTRACT(days FROM r.employee_join_date - DATE_TRUNC('month', NOW()));
        END IF;
        IF r.employee_depart_date IS NULL THEN
            last_work_day := num_days_in_month;
        ELSE
            last_work_day := EXTRACT(days FROM r.employee_join_date - DATE_TRUNC('month', NOW()));
        END IF;
        num_work_days := last_work_day - first_work_day + 1;

        hourly_rate := NULL;
        monthly_salary := r.employee_monthly_salary;

        amount_paid := monthly_salary * num_work_days / num_days_in_month;

        INSERT INTO PaySlips(employee_id, payslip_date, payslip_amount, payslip_num_work_hours, payslip_num_work_days)
        VALUES (employee_id, CURRENT_DATE, amount_paid, num_work_hours, num_work_days);
        RETURN NEXT;
    END LOOP;
    CLOSE curs_full_time;
END;
$$ LANGUAGE plpgsql;

/*
    28. popular_courses: This routine is used to find the popular courses offered this year (i.e., start date is within this year).
    A course is popular if the course has at least two offerings this year, and for every pair of offerings of the course this year, the offering with the later start date has a higher number of registrations than that of the offering with the earlier start date.
    The routine returns a table of records consisting of the following information for each popular course:
        course identifier,
        course title,
        course area,
        number of offerings this year, and
        number of registrations for the latest offering this year.
    The output is sorted in
        descending order of the number of registrations for the latest offering this year followed by in
        ascending order of course identifier.
*/
DROP FUNCTION IF EXISTS get_offering_num_enrolled CASCADE;
CREATE OR REPLACE FUNCTION get_offering_num_enrolled (
    offering_launch_date_arg DATE,
    course_id_arg INTEGER
) RETURNS INTEGER AS $$
DECLARE
    num_enrolled INTEGER;
BEGIN
    SELECT SUM(r.room_seating_capacity - get_session_num_remaining_seats(s.session_id, s.offering_launch_date, s.course_id)) 
    INTO num_enrolled
    FROM Sessions s
    NATURAL JOIN Rooms r
    WHERE s.offering_launch_date = offering_launch_date_arg
        AND s.course_id = course_id_arg;

    num_enrolled := COALESCE(num_enrolled, 0);

    RETURN num_enrolled;
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS popular_courses CASCADE;
CREATE OR REPLACE FUNCTION popular_courses()
RETURNS TABLE(
    course_id INTEGER,
    course_title TEXT,
    course_area_name TEXT,
    num_course_offerings INTEGER,
    num_latest_registrations INTEGER
) AS $$
BEGIN
    RETURN QUERY (
        SELECT
            c.course_id,
            c.course_title,
            ca.course_area_name,
            /* number of course offerings this year */
            (
                SELECT COUNT(co.offering_launch_date)::INTEGER
                FROM CourseOfferings co
                WHERE co.course_id = c.course_id
                    AND DATE_PART('YEAR', co.offering_start_date) = DATE_PART('YEAR', CURRENT_DATE)
            ) AS num_course_offerings,
            /* number of registrations for latest offering this year */
            (
                SELECT get_offering_num_enrolled(co.offering_launch_date, co.course_id)
                FROM CourseOfferings co
                WHERE co.course_id = c.course_id
                    AND DATE_PART('YEAR', co.offering_start_date) = DATE_PART('YEAR', CURRENT_DATE)
                ORDER BY co.offering_launch_date DESC
                LIMIT 1
            ) AS num_latest_registrations
        FROM Courses c
        NATURAL JOIN CourseAreas ca
        WHERE (
                SELECT COUNT(co.offering_launch_date)
                FROM CourseOfferings co
                WHERE co.course_id = c.course_id
                    AND DATE_PART('YEAR', co.offering_start_date) = DATE_PART('YEAR', CURRENT_DATE)
            ) >= 2
            /* All pairs of earlier -> later course offerings this year must have increasing number of registrations */
            AND TRUE = ALL(
                SELECT (
                    get_offering_num_enrolled(co.offering_launch_date, co.course_id) <
                    get_offering_num_enrolled(co2.offering_launch_date, co2.course_id)
                ) AS isIncreasinglyPopular
                FROM CourseOfferings co, CourseOfferings co2
                WHERE c.course_id = co.course_id
                    AND co.course_id = co2.course_id
                    AND DATE_PART('YEAR', co.offering_start_date) = DATE_PART('YEAR', CURRENT_DATE)
                    AND DATE_PART('YEAR', co.offering_start_date) = DATE_PART('YEAR', co2.offering_start_date)
                    AND co.offering_start_date < co2.offering_start_date
            )
        ORDER BY num_latest_registrations DESC, c.course_id ASC
    );

    IF NOT FOUND THEN
        RAISE NOTICE 'No popular courses in this year.';
    END IF;
END;
$$ LANGUAGE PLPGSQL;

/*
    26. promote_courses: This routine is used to identify potential course offerings that could be of interest to inactive customers.
    A customer is classified as an active customer if the customer has registered for some course offering in the last six months (inclusive of the current month);
    otherwise, the customer is considered to be inactive customer.
    A course area A is of interest to a customer C if there is some course offering in area A among the three most recent course offerings registered by C.
    If a customer has not yet registered for any course offering, we assume that every course area is of interest to that customer.
    The routine returns a table of records consisting of the following information for each inactive customer:
        customer identifier,
        customer name,
        course area A that is of interest to the customer,
        course identifier of a course C in area A,
        course title of C,
        launch date of course offering of course C that still accepts registrations,
        course offering's registration deadline, and
        fees for the course offering.
    The output is sorted in
        ascending order of customer identifier and
        course offering's registration deadline.

    Design Note:
        It is possible that a customer registers or redeems some sessions at the exact same time.
        In such cases, tiebreaking between the 3 latest course offerings registered/redeemed by customer C is performed using the course area name of the respective course (smaller lexicographical order wins).

        We further impose a constraint on the results returned:
        Courses that are currently/previously enrolled (i.e. having some course offering session redeemed or registered that is not cancelled) by a customer should not be promoted to the same customer. This is because it does not make sense to promote to a customer a course he/she has previously attended/is going to attend (if the course session has not started despite signing up > 6 months ago).
*/
DROP FUNCTION IF EXISTS promote_courses CASCADE;
CREATE OR REPLACE FUNCTION promote_courses()
RETURNS TABLE(
    customer_id INTEGER,
    customer_name TEXT,
    course_area_name TEXT,
    course_id INTEGER,
    course_title TEXT,
    offering_launch_date DATE,
    offering_registration_deadline DATE,
    offering_fees DEC(64,2))
AS $$
BEGIN
    RETURN QUERY (
        /* Try to find the last 3 sessions registered for each customer */
        WITH LastThreeSessionsRegistered AS (
            SELECT r.customer_id, r.register_timestamp AS enrol_date, c.course_area_name
            FROM Registers r
            NATURAL JOIN Sessions s
            NATURAL JOIN CourseOfferings co
            NATURAL JOIN Courses c
            WHERE r.register_timestamp IN (
                SELECT r2.register_timestamp
                FROM Registers r2
                WHERE r2.customer_id = r.customer_id
                ORDER BY r2.register_timestamp DESC, c.course_area_name ASC
                LIMIT 3
            )
        ),
        /* Try to find the last 3 sessions redeemed for each customer - this is to identify course areas of interest for each customer */
        LastThreeSessionsRedeemed AS (
            SELECT b.customer_id, r.redeem_timestamp AS enrol_date, c.course_area_name
            FROM Redeems r
            NATURAL JOIN Buys b
            NATURAL JOIN Sessions s
            NATURAL JOIN CourseOfferings co
            NATURAL JOIN Courses c
            WHERE r.redeem_timestamp IN (
                SELECT r2.redeem_timestamp
                FROM Redeems r2
                NATURAL JOIN Buys b2
                WHERE b2.customer_id = b.customer_id
                ORDER BY r2.redeem_timestamp DESC, c.course_area_name ASC
                LIMIT 3
            )
        ),
        /* Merging last 3 sessions registered and redeemed for each customer should give at most 6 sessions */
        LastSixSessionsRegisteredOrRedeemed AS (
            SELECT DISTINCT r.customer_id, r.enrol_date, r.course_area_name
            FROM LastThreeSessionsRegistered r
            UNION 
            SELECT r.customer_id, r.enrol_date, r.course_area_name
            FROM LastThreeSessionsRedeemed r
        ),
        /* Then, filter out the 3 latest sessions registered/redeemed */
        LastThreeSessionsEnrolled AS (
            SELECT e.customer_id, e.enrol_date, e.course_area_name
            FROM LastSixSessionsRegisteredOrRedeemed e
            /* Here, filter out the 3 latest sessions for each customer  */
            WHERE e.enrol_date IN (
                SELECT e2.enrol_date
                FROM LastSixSessionsRegisteredOrRedeemed e2
                WHERE e2.customer_id = e.customer_id
                    AND e2.enrol_date >= (NOW() - interval '6 months') /*Filter the date of the transaction*/
                ORDER BY e2.enrol_date DESC, e2.course_area_name ASC
                LIMIT 3
            )
        ),
        /*
            A customer is classified as an active customer if the customer has registered for some course offering in the last six months (inclusive of the current month);
            otherwise, the customer is considered to be inactive customer.
        */
        InactiveCustomersCourseAreasPairs AS (
            /* select all customers without any course offerings directly */
            SELECT c.customer_id, c.customer_name, ca.course_area_name
            FROM Customers c, CourseAreas ca
            WHERE c.customer_id NOT IN (SELECT e.customer_id FROM LastThreeSessionsEnrolled e)
            UNION
            /* select all inactive customers only */
            SELECT e.customer_id, c.customer_name, e.course_area_name
            FROM LastThreeSessionsEnrolled e
            NATURAL JOIN Customers c
        ),
        InactiveCustomers AS (
            SELECT DISTINCT pair.customer_id, pair.customer_name
            FROM InactiveCustomersCourseAreasPairs pair
        ),
        AllSessionsEnrolled AS (
            SELECT DISTINCT r.customer_id, c.course_id
            FROM Registers r
            NATURAL JOIN Sessions s
            NATURAL JOIN CourseOfferings co
            NATURAL JOIN Courses c
            WHERE r.register_cancelled IS NOT TRUE
            UNION
            SELECT b.customer_id, c.course_id
            FROM Redeems r
            NATURAL JOIN Buys b
            NATURAL JOIN Sessions s
            NATURAL JOIN CourseOfferings co
            NATURAL JOIN Courses c
            WHERE r.redeem_cancelled IS NOT TRUE
        )
        SELECT DISTINCT ic.customer_id,
            ic.customer_name,
            c.course_area_name,
            co.course_id,
            c.course_title,
            co.offering_launch_date,
            co.offering_registration_deadline,
            co.offering_fees
        FROM InactiveCustomers ic, CourseOfferings co
        NATURAL JOIN Courses c
        WHERE c.course_area_name IN (
            SELECT pair.course_area_name
            FROM InactiveCustomersCourseAreasPairs pair
            WHERE pair.customer_id = ic.customer_id
        ) AND c.course_title IN (
            SELECT co2.course_title FROM get_available_course_offerings() co2
        ) AND co.offering_registration_deadline >= CURRENT_DATE
        AND co.course_id NOT IN (
            SELECT e.course_id
            FROM AllSessionsEnrolled e
            WHERE e.customer_id = ic.customer_id
        )
        ORDER BY ic.customer_id ASC,
            co.offering_registration_deadline ASC
    );
END;
$$ LANGUAGE plpgsql;

/*
    17. register_session: This routine is used when a customer requests to register for a session in a course offering.
    The inputs to the routine include the following:
        customer identifier,
        course offering identifier,
        session number, and
        payment method (credit card or redemption from active package).
    If the registration transaction is valid, this routine will process the registration with the necessary updates (e.g., payment/redemption).
*/
DROP FUNCTION IF EXISTS register_session CASCADE;
CREATE OR REPLACE FUNCTION register_session (
    offering_launch_date_arg DATE,
    course_id_arg INTEGER,
    session_id_arg INTEGER,
    customer_id_arg INTEGER,
    payment_method TEXT
) RETURNS VOID
AS $$
DECLARE
    credit_card_number_var CHAR(16);
    buy_timestamp_arg TIMESTAMP;
    package_id_arg INTEGER;
    buy_num_remaining_redemptions_arg INTEGER;
BEGIN
    /* Check for NULLs in arguments */
    IF offering_launch_date_arg IS NULL
        OR course_id_arg IS NULL
        OR session_id_arg IS NULL
        OR customer_id_arg IS NULL
        OR payment_method IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to register_session() cannot contain NULL values.';
    END IF;

    /* Check if session to be registered/redeemed exists */
    IF NOT EXISTS(
        SELECT session_id FROM Sessions s
        WHERE s.offering_launch_date = offering_launch_date_arg
            AND s.course_id = course_id_arg
            AND s.session_id = session_id_arg
    ) THEN
        RAISE EXCEPTION 'Session does not exist.';
    END IF;

    /* Check if customer exists */
    IF NOT EXISTS(SELECT customer_id FROM Customers c WHERE c.customer_id = customer_id_arg)
    THEN
        RAISE EXCEPTION 'Customer ID % does not exist.', customer_id_arg;
    END IF;

    /* Check if the payment method is valid */
    IF (payment_method NOT IN ('Redemption', 'Credit Card')) THEN
        RAISE EXCEPTION 'Invalid payment type';
    END IF;

    /* Check if customer has an active registration/redemption of course offering */
    IF EXISTS(
        SELECT e.enroll_timestamp
        FROM Enrolment e
        WHERE e.customer_id = customer_id_arg
            AND e.offering_launch_date = offering_launch_date_arg
            AND e.course_id = course_id_arg
    ) THEN
        RAISE EXCEPTION 'Customer has already enrolled (either registered or redeemed) for a session in the Course Offering!';
    END IF;

    IF payment_method = 'Redemption'
    THEN
        SELECT b.buy_timestamp, b.package_id ,b.buy_num_remaining_redemptions
        INTO buy_timestamp_arg, package_id_arg, buy_num_remaining_redemptions_arg
        FROM Buys b
        WHERE b.customer_id = customer_id_arg
            AND b.buy_num_remaining_redemptions >= 1
            ORDER BY b.buy_num_remaining_redemptions ASC
            LIMIT 1;

        IF package_id_arg IS NULL
        THEN
            RAISE EXCEPTION 'No active packages!';
        END IF;

        UPDATE Buys
        SET buy_num_remaining_redemptions = (buy_num_remaining_redemptions_arg - 1)
        WHERE customer_id = customer_id_arg
            AND package_id = package_id_arg
            AND buy_timestamp = buy_timestamp_arg;

        INSERT INTO Redeems
        (redeem_timestamp, buy_timestamp, session_id, offering_launch_date, course_id)
        VALUES
        (statement_timestamp(), buy_timestamp_arg, session_id_arg, offering_launch_date_arg, course_id_arg);

    ELSIF payment_method = 'Credit Card' THEN
        SELECT o.credit_card_number INTO credit_card_number_var
        FROM Owns o
        WHERE o.customer_id = customer_id_arg;

        IF credit_card_number_var IS NULL THEN
            RAISE EXCEPTION 'Credit card is invalid';
        END IF;

        /*Check for the expiry of the credit card in the trigger for registers*/
        INSERT INTO Registers
        (register_timestamp, customer_id, credit_card_number, session_id, offering_launch_date, course_id)
        VALUES
        (statement_timestamp(), customer_id_arg, credit_card_number_var, session_id_arg, offering_launch_date_arg, course_id_arg);
    ELSE
        /*Just to be extra safe*/
        RAISE EXCEPTION 'Invalid Payment Method';
    END IF;
END;
$$ LANGUAGE plpgsql;

/*
    2. remove_employee: This routine is used to update an employee's departed date a non-null value.
    The inputs to the routine is
        an employee identifier and
        a departure date.
    The update operation is rejected if any one of the following conditions hold:
        (1) the employee is an administrator who is handling some course offering where its registration deadline is after the employee's departure date;
        (2) the employee is an instructor who is teaching some course session that starts after the employee's departure date; or
        (3) the employee is a manager who is managing some area.
*/

DROP FUNCTION IF EXISTS is_active_admin CASCADE;
CREATE OR REPLACE FUNCTION is_active_admin(admin_id_arg INTEGER, departure_date DATE)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(SELECT * FROM CourseOfferings co WHERE co.admin_id = admin_id_arg AND co.offering_registration_deadline > departure_date);
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS is_active_manager CASCADE;
CREATE OR REPLACE FUNCTION is_active_manager (manager_id_arg INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS(SELECT * FROM CourseAreas ca WHERE ca.manager_id = manager_id_arg);
END;
$$ LANGUAGE PLPGSQL;

DROP FUNCTION IF EXISTS remove_employee CASCADE;
CREATE OR REPLACE FUNCTION remove_employee (
    employee_id_arg INTEGER,
    employee_depart_date_arg DATE
) RETURNS VOID
AS $$
BEGIN
    /* Check for NULLs in arguments */
    IF employee_id_arg IS NULL
        OR employee_depart_date_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to remove_employee() cannot contain NULL values.';
    END IF;

    /* The below conditions needs changing; need to check if it's managing a course offering/session AFTER departure date */
    IF employee_id_arg NOT IN (SELECT employee_id FROM Employees)
    THEN
        RAISE EXCEPTION 'Employee identifier % does not exist', employee_id_arg;
    /* Check if they are still handling admin tasks */
    ELSIF is_active_admin(employee_id_arg, employee_depart_date_arg) IS TRUE
    THEN
        RAISE EXCEPTION 'Employee is still an administrator for a course offering that starts after departure date.';
    /* Check if they are manager managing some area */
    ELSIF is_active_manager(employee_id_arg) IS TRUE
    THEN
        RAISE EXCEPTION 'Employee is still managing a course area.';
    /* Check if they are still teaching some course past employee's departure date */
    ELSIF EXISTS(SELECT * FROM Sessions s WHERE s.instructor_id = employee_id_arg AND s.session_date >= employee_depart_date_arg) THEN
        RAISE EXCEPTION 'Employee is still teaching a session after departure date.';
    END IF;

    /* Leave it to insert/update CHECK() to ensure employee_depart_date_arg is >= join_date */
    UPDATE Employees e
    SET employee_depart_date = employee_depart_date_arg
    WHERE e.employee_id = employee_id_arg;
END;
$$ LANGUAGE plpgsql;

/*
    23. remove_session: This routine is used to remove a course session.
    The inputs to the routine include the following:
        course offering identifier and
        session number.
    If the course session has not yet started and the request is valid, the routine will process the request with the necessary updates.
    The request must not be performed if there is at least one registration for the session.
    Note that the resultant seating capacity of the course offering could fall below the course offering's target number of registrations, which is allowed.

    Design Notes:
        Since each course offering consists of one or more sessions, if the session to be deleted is the only session of the course offering, the deletion request will NOT be processed.
*/
DROP FUNCTION IF EXISTS remove_session;
CREATE OR REPLACE FUNCTION remove_session (
    course_id_arg               INTEGER,
    offering_launch_date_arg    DATE,
    session_id_arg              INTEGER
) RETURNS VOID
AS $$
DECLARE
    session_date            DATE;
    session_start_hour      INTEGER;
    room_seating_capacity   INTEGER;
BEGIN
    /* Check for NULLs in arguments */
    IF course_id_arg IS NULL
        OR offering_launch_date_arg IS NULL
        OR session_id_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to remove_session() cannot contain NULL values.';
    END IF;

    /* Check if arguments yield a valid session */
    SELECT s.session_date, s.session_start_hour, r.room_seating_capacity
        INTO session_date, session_start_hour, room_seating_capacity
    FROM Sessions s
    NATURAL JOIN Rooms r
    WHERE s.course_id = course_id_arg
        AND s.offering_launch_date = offering_launch_date_arg
        AND s.session_id = session_id_arg;

    IF session_date IS NULL THEN
        RAISE EXCEPTION 'Given session does not exist.';
    END IF;

    IF (CURRENT_DATE > session_date)
        OR (CURRENT_DATE = session_date AND EXTRACT(HOUR FROM NOW()) >= session_start_hour) THEN
        RAISE EXCEPTION 'Cannot remove session that has already started.';
    END IF;

    IF EXISTS(
        SELECT e.enroll_timestamp
        FROM Enrolment e
        WHERE e.course_id = course_id_arg
            AND e.offering_launch_date = offering_launch_date_arg
            AND e.session_id = session_id_arg
    )
    THEN
        RAISE EXCEPTION 'Cannot remove session that has at least one student.';
    END IF;

    IF (
        SELECT COUNT(*)
        FROM Sessions s
        WHERE s.course_id = course_id_arg
        AND s.offering_launch_date = offering_launch_date_arg
    ) = 1 THEN
        RAISE EXCEPTION 'Cannot delete the only session of a course offering (each course offering must have at least one session).';
    END IF;

    DELETE FROM Sessions s
    WHERE s.course_id = course_id_arg
        AND s.offering_launch_date = offering_launch_date_arg
        AND s.session_id = session_id_arg;

    UPDATE CourseOfferings co
    SET offering_seating_capacity = (offering_seating_capacity - room_seating_capacity)
    WHERE co.course_id = course_id_arg
        AND co.offering_launch_date = offering_launch_date_arg;
END;
$$ LANGUAGE plpgsql;

/*
    27. top_packages: This routine is used to find the top N course packages in terms of the total number of packages sold for this year (i.e., the package's start date is within this year).
    The input to the routine is a positive integer number N.
    The routine returns a table of records consisting of the following information for each of the top N course packages:
        package identifier,
        number of included free course sessions,
        price of package,
        start date,
        end date, and
        number of packages sold.
    The output is sorted in
        descending order of number of packages sold followed by
        descending order of price of package.
    In the event that there are multiple packages that tie for the top Nth position, all these packages should be included in the output records;
    thus, the output table could have more than N records.
    It is also possible for the output table to have fewer than N records if N is larger than the number of packages launched this year.
*/
DROP FUNCTION IF EXISTS top_packages CASCADE;
CREATE OR REPLACE FUNCTION top_packages (
    N INTEGER
)
RETURNS TABLE (
    package_id INTEGER,
    package_num_free_registrations INTEGER,
    package_price DEC(64, 2),
    package_sale_start_date DATE,
    package_sale_end_date DATE,
    packages_num_sold INTEGER
)
    AS $$
BEGIN
    /* Check for NULLs in arguments */
    IF N IS NULL OR N <= 0
    THEN
        RAISE EXCEPTION 'Number of top packages to find must be a positive integer.';
    END IF;

    RETURN QUERY (
        WITH
        /* excluded packages that are not sold */
        PackagesSold AS
        (
            SELECT c.package_id, COUNT(*) AS packages_num_sold
            FROM CoursePackages c NATURAL JOIN Buys b
            GROUP BY c.package_id
        ),
        /* use rank because according to requirements:
            "In the event that there are multiple packages that tie for the top Nth position,
            all these packages should be included in the output records"
        */
        PackagesWithRank AS
        (
            SELECT c.package_id, c.package_num_free_registrations, c.package_price, c.package_sale_start_date,
                   c.package_sale_end_date, p.packages_num_sold,
                   RANK() OVER (ORDER BY p.packages_num_sold DESC) AS package_rank
            FROM CoursePackages c NATURAL JOIN PackagesSold p
        )
        /*Required cast to integer to return as integer. Otherwise returns as BIGINT*/
        SELECT p.package_id, p.package_num_free_registrations, p.package_price, p.package_sale_start_date,
           p.package_sale_end_date, p.packages_num_sold::INTEGER
        FROM PackagesWithRank p
        WHERE p.package_rank <= N
        ORDER BY p.packages_num_sold DESC, p.package_price DESC
    );
END;
$$ LANGUAGE plpgsql;

/*
    19. update_course_session: This routine is used when a customer requests to change a registered course session to another session.
    The inputs to the routine include the following:
        customer identifier,
        course offering identifier,
        and new session number.
    If the update request is valid and there is an available seat in the new session, the routine will process the request with the necessary updates.
*/
DROP FUNCTION IF EXISTS update_course_session CASCADE;
CREATE OR REPLACE FUNCTION update_course_session (
    r_customer_id           INTEGER,
    r_course_id             INTEGER,
    r_offering_launch_date  DATE,
    new_session_id          INTEGER
) RETURNS VOID
AS $$
DECLARE
    enroll_timestamp        TIMESTAMP;
    old_session_id          INTEGER;
    enrolment_table         TEXT;
    num_seats_available     INTEGER;
    new_session_count       INTEGER;
BEGIN
    /* Check for NULLs in arguments */
    IF r_customer_id IS NULL
        OR r_course_id IS NULL
        OR r_offering_launch_date IS NULL
        OR new_session_id IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to update_course_session() cannot contain NULL values.';
    END IF;

    SELECT COUNT(s.session_date) INTO new_session_count
        FROM Sessions s
        WHERE s.course_id = r_course_id
            AND s.offering_launch_date = r_offering_launch_date
            AND s.session_id = new_session_id;

    /* Check if session identifier supplied exists */
    IF (new_session_count <= 0) THEN
        RAISE EXCEPTION 'Session not found. Check if the session identifier (course_id, offering_launch_date and session_id) are correct.';
    /* Check if customer identifier supplied exists */
    ELSIF NOT EXISTS(
        SELECT c.customer_id FROM Customers c WHERE c.customer_id = r_customer_id
    ) THEN
        RAISE EXCEPTION 'Customer ID not found.';
    END IF;

    /* Check if customer is enrolled in session specified */
    SELECT e.enroll_timestamp, e.session_id, e.table_name
    INTO enroll_timestamp, old_session_id, enrolment_table
    FROM Enrolment e
    WHERE e.customer_id = r_customer_id
        AND e.course_id = r_course_id
        AND e.offering_launch_date = r_offering_launch_date;

    IF enroll_timestamp IS NULL THEN
        RAISE EXCEPTION 'Customer is not registered to any session for this course offering.';
    END IF;

    SELECT (r.room_seating_capacity - c.num_enrolled) INTO num_seats_available
    FROM Sessions s NATURAL JOIN Rooms r NATURAL JOIN EnrolmentCount c
    WHERE s.course_id = r_course_id
        AND s.offering_launch_date = r_offering_launch_date
        AND s.session_id = new_session_id;

    IF num_seats_available <= 0 THEN
        RAISE EXCEPTION 'Customer cannot change to this session because there are no seats remaining in the room.';
    END IF;

    IF enrolment_table = 'registers' THEN
        UPDATE Registers r
        SET session_id = new_session_id
        WHERE r.register_timestamp = enroll_timestamp;
    ELSE
        UPDATE Redeems r
        SET session_id = new_session_id
        WHERE r.redeem_timestamp = enroll_timestamp;
    END IF;
END;
$$ LANGUAGE plpgsql;

/*
    4. update_credit_card: This routine is used when a customer requests to change his/her credit card details.
    The inputs to the routine include
        the customer identifier and
        his/her new credit card details (credit card number, expiry date, CVV code).
*/
DROP FUNCTION IF EXISTS update_credit_card CASCADE;
CREATE OR REPLACE FUNCTION update_credit_card (
    customer_id INTEGER,
    credit_card_number CHAR(16),
    credit_card_cvv CHAR(3),
    credit_card_expiry_date DATE
) RETURNS VOID
AS $$
BEGIN
    /* Check for NULLs in arguments */
    IF customer_id IS NULL
        OR credit_card_number IS NULL
        OR credit_card_cvv IS NULL
        OR credit_card_expiry_date IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to update_credit_card() cannot contain NULL values.';
    END IF;

    INSERT INTO CreditCards
    (credit_card_number, credit_card_cvv, credit_card_expiry_date)
    VALUES
    (credit_card_number, credit_card_cvv, credit_card_expiry_date);

    INSERT INTO Owns
    (customer_id, credit_card_number, own_from_timestamp)
    VALUES
    (customer_id, credit_card_number, CURRENT_DATE);
END;
$$ LANGUAGE plpgsql;

/*
    21. update_instructor: This routine is used to change the instructor for a course session.
    The inputs to the routine include the following:
        course offering identifier,
        session number, and
        identifier of the new instructor.
    If the course session has not yet started and the update request is valid, the routine will process the request with the necessary updates.
*/
DROP FUNCTION IF EXISTS update_instructor CASCADE;
CREATE OR REPLACE FUNCTION update_instructor (
    offering_launch_date_arg DATE,
    course_id_arg INTEGER,
    session_id_arg INTEGER,
    instructor_id_arg INTEGER
) RETURNS VOID
AS $$
DECLARE
    session_date DATE;
    session_start_hour INTEGER;
    session_instructor_id INTEGER;
BEGIN
    /* Check for NULLs in arguments */
    IF offering_launch_date_arg IS NULL
        OR course_id_arg IS NULL
        OR session_id_arg IS NULL
        OR instructor_id_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to update_instructor() cannot contain NULL values.';
    END IF;

    SELECT s.session_date, s.session_start_hour, s.instructor_id
    INTO session_date, session_start_hour, session_instructor_id
    FROM Sessions s
    WHERE s.session_id = session_id_arg
        AND s.offering_launch_date = offering_launch_date_arg
        AND s.course_id = course_id_arg;

    /* Check if session identifier is valid */
    IF session_date IS NULL
    THEN
        RAISE EXCEPTION 'Session identifier supplied is invalid.';
    /* Check if employee ID is a valid instructor */
    ELSIF instructor_id_arg NOT IN (SELECT instructor_id FROM Instructors)
    THEN
        RAISE EXCEPTION 'Employee ID supplied is invalid (either not an instructor or the employee ID does not exist).';
    END IF;

    IF (session_date < CURRENT_DATE)
        OR (session_date = CURRENT_DATE AND session_start_hour <= EXTRACT(HOUR FROM CURRENT_TIME))
    THEN
        RAISE EXCEPTION 'Session already started! Cannot update instructor!';
    END IF;

    IF instructor_id_arg = session_instructor_id
    THEN
        RAISE NOTICE 'Updating the instructor of the session to the same instructor currently assigned to the session has no effect!';
    ELSIF instructor_id_arg NOT IN (SELECT employee_id FROM find_instructors(course_id_arg, session_date, session_start_hour))
    THEN
        RAISE EXCEPTION 'This instructor cannot teach this session!';
    ELSE
        /* Update the table */
        UPDATE Sessions s
        SET instructor_id = instructor_id_arg
        WHERE s.offering_launch_date = offering_launch_date_arg
        AND s.course_id = course_id_arg
        AND s.session_id = session_id_arg;
    END IF;
END;
$$ LANGUAGE plpgsql;

/*
    22. update_room: This routine is used to change the room for a course session.
    The inputs to the routine include the following:
        course offering identifier,
        session number, and
        identifier of the new room.
    If the course session has not yet started and the update request is valid, the routine will process the request with the necessary updates.
    Note that update request should not be performed if the number of registrations for the session exceeds the seating capacity of the new room.
*/
DROP FUNCTION IF EXISTS array_includes_range CASCADE;
CREATE OR REPLACE FUNCTION array_includes_range(
    int_array INTEGER[],
    int_start INTEGER,
    int_end INTEGER
) RETURNS BOOLEAN AS $$
DECLARE
    total_ints INTEGER;
BEGIN
    total_ints := int_end - int_start;

    /* Count number of distinct integers in array range */
    /* E.g. if a session starts at 9am and ends at 12pm, the array (available hours) needs to include 9, 10, 11 */
    /* Note: Between is inclusive */
    RETURN total_ints = (
        SELECT (COUNT(DISTINCT arr.i))
        FROM (SELECT unnest(int_array) AS i) AS arr
        WHERE arr.i BETWEEN int_start AND int_end - 1
    );
END;
$$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS update_room CASCADE;
CREATE OR REPLACE FUNCTION update_room(
    offering_launch_date_arg DATE,
    course_id_arg INTEGER,
    session_id_arg INTEGER,
    room_id_arg INTEGER
) RETURNS VOID AS $$
DECLARE
    current_room_id INTEGER;
    session_date DATE;
    num_enrolled INTEGER;
    session_start_hour INTEGER;
    session_end_hour INTEGER;
    available_hours INTEGER[];
    old_room_seating_capacity INTEGER;
    new_room_seating_capacity INTEGER;
BEGIN
    /* Check for NULLs in arguments */
    IF offering_launch_date_arg IS NULL
        OR course_id_arg IS NULL
        OR session_id_arg IS NULL
        OR room_id_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to update_room() cannot contain NULL values.';
    END IF;

    /* Check if arguments yield a valid session */
    SELECT s.session_date, s.session_start_hour, s.session_end_hour, s.room_id, r.room_seating_capacity
    INTO session_date, session_start_hour, session_end_hour, current_room_id, old_room_seating_capacity
    FROM Sessions s
    NATURAL JOIN Rooms r
    WHERE s.offering_launch_date = offering_launch_date_arg
        AND s.course_id = course_id_arg
        AND s.session_id = session_id_arg;

    IF session_date IS NULL THEN
        RAISE EXCEPTION 'Session not found. Check if the course offering identifier (course_id and offering_launch_date) are correct.';
    END IF;

    /* Check if arguments yield a valid room */
    IF NOT EXISTS(SELECT room_id FROM Rooms r WHERE r.room_id = room_id_arg) THEN
        RAISE EXCEPTION 'Room id % does not exists', room_id_arg;
    END IF;

    /* Check if room seating capacity can accomodate all active registrations now */
    SELECT COUNT(*) INTO num_enrolled
    FROM Enrolment e
    WHERE e.session_id = session_id_arg
        AND e.offering_launch_date = offering_launch_date_arg
        AND e.course_id = course_id_arg;

    SELECT r.room_seating_capacity INTO new_room_seating_capacity
    FROM Rooms r
    WHERE room_id_arg = r.room_id;

    IF num_enrolled > new_room_seating_capacity
    THEN
        RAISE EXCEPTION 'Cannot accomodate all active registrations in room %.', room_id_arg;
    END IF;

    /* Check room availability */
    SELECT r.available_hours INTO available_hours
    FROM get_available_rooms(session_date, session_date) r
    WHERE r.room_id = room_id_arg;

    /* Also check that entire range of hours used by the session is available */
    IF available_hours IS NULL OR NOT array_includes_range(available_hours, session_start_hour, session_end_hour)
    THEN
        RAISE EXCEPTION 'Room % is already in use', room_id_arg;
    ELSIF (
        /* Prevent updating of sessions that already started/ended. */
        CURRENT_DATE > session_date
        OR (CURRENT_DATE = session_date AND session_start_hour <= EXTRACT(HOUR FROM CURRENT_TIME))
    ) THEN
        RAISE EXCEPTION 'Cannot update room when the session already started.';
    END IF;

    /* Warn user when updating to same room */
    IF current_room_id = room_id_arg
    THEN
        RAISE NOTICE 'Assigning the same room to the session has no effect!';
        RETURN;
    END IF;

    UPDATE Sessions s
    SET room_id = room_id_arg
    WHERE s.session_id = session_id_arg
        AND s.offering_launch_date = offering_launch_date_arg
        AND s.course_id = course_id_arg;

    UPDATE CourseOfferings co
    SET offering_seating_capacity = (offering_seating_capacity - old_room_seating_capacity + new_room_seating_capacity)
    WHERE co.course_id = course_id_arg
        AND co.offering_launch_date = offering_launch_date_arg;
END;
$$ LANGUAGE plpgsql;

/*
    30. view_manager_report:  This routine is used to view a report on the sales generated by each manager.
    The routine returns a table of records consisting of the following information for each manager:
        manager name,
        total number of course areas that are managed by the manager,
        total number of course offerings that ended this year
            (i.e., the course offering’s end date is within this year) that are managed by the manager,
        total net registration fees for all the course offerings that ended this year that are managed by the manager,
        the course offering title (i.e., course title)
            that has the highest total net registration fees among all the course offerings
            that ended this year that are managed by the manager;
            if there are ties, list all these top course offering titles.

    The total net registration fees for a course offering is defined to be
        the sum of the total registration fees paid for the course offering via credit card payment
        (excluding any refunded fees due to cancellations)
        and the total redemption registration fees for the course offering.
    The redemption registration fees for a course offering refers to the registration fees for a course offering
        that is paid via a redemption from a course package;
        this registration fees is given by the price of the course package divided by
        the number of sessions included in the course package (rounded down to the nearest dollar).

    There must be one output record for each manager in the company and
        the output is to be sorted by ascending order of manager name.
*/
DROP FUNCTION IF EXISTS view_manager_report CASCADE;
CREATE OR REPLACE FUNCTION view_manager_report()
RETURNS TABLE (
    manager_name                TEXT,
    num_course_areas            INTEGER,
    num_course_offerings        INTEGER,
    net_registration_fees       DEC(64, 2),
    top_course_offering_titles  TEXT[]
)
AS $$
BEGIN
    RETURN QUERY (
        /* names */
        WITH ManagerNames AS (
            SELECT manager_id, employee_name AS manager_name
            FROM Managers m
            JOIN Employees e ON m.manager_id = e.employee_id
        ),
        /* course areas */
        ManagerNumCourseAreas AS (
            SELECT manager_id, COUNT(*)::INTEGER as num_course_areas
            FROM Managers
            NATURAL LEFT OUTER JOIN CourseAreas
            GROUP BY manager_id
        ),

        /* course offerings */
        CourseOfferingsThisYear AS (
            SELECT *
            FROM CourseOfferings
            WHERE EXTRACT(YEAR FROM offering_end_date) = EXTRACT(YEAR FROM CURRENT_DATE)
        ),
        ManagerCourseOfferings AS (
            SELECT manager_id, course_id, offering_launch_date
            FROM CourseOfferingsThisYear
            NATURAL JOIN Courses
            NATURAL JOIN CourseAreas
        ),
        ManagerNumCourseOfferings AS (
            SELECT manager_id, COUNT(*)::INTEGER AS num_course_offerings
            FROM Managers
            NATURAL LEFT OUTER JOIN ManagerCourseOfferings
            GROUP BY manager_id
        ),

        /* registration fees */
        CourseOfferingCreditCardRegistrationFees AS (
            SELECT offering_launch_date, course_id, SUM(offering_fees) AS total_registration_fees
            FROM Registers
            NATURAL JOIN Sessions
            NATURAL JOIN CourseOfferingsThisYear
            GROUP BY offering_launch_date, course_id
        ),
        CourseOfferingCreditCardRefundFees AS (
            SELECT offering_launch_date, course_id, COALESCE(SUM(cancel_refund_amount), 0.00) AS total_refunded_fees
            FROM Cancels
            NATURAL JOIN Sessions
            NATURAL JOIN CourseOfferingsThisYear
            GROUP BY offering_launch_date, course_id
        ),
        RedemptionRegistrationFees AS (
            SELECT redeem_timestamp, FLOOR(package_price / package_num_free_registrations) AS redemption_fees
            FROM Redeems
            NATURAL JOIN Buys
            NATURAL JOIN CoursePackages
        ),
        CourseOfferingRedemptionRegistrationFees AS (
            SELECT offering_launch_date, course_id, SUM(redemption_fees) AS total_redemption_fees
            FROM Redeems
            NATURAL JOIN RedemptionRegistrationFees
            NATURAL JOIN Sessions
            NATURAL JOIN CourseOfferingsThisYear
            WHERE NOT redeem_cancelled
            GROUP BY offering_launch_date, course_id
        ),
        CourseOfferingNetRegistrationFees AS (
            SELECT offering_launch_date,
                course_id,
                SUM(COALESCE(total_registration_fees, 0) - COALESCE(total_refunded_fees, 0) + COALESCE(total_redemption_fees, 0)) AS net_registration_fees
            FROM CourseOfferingsThisYear
            NATURAL FULL OUTER JOIN CourseOfferingCreditCardRegistrationFees
            NATURAL FULL OUTER JOIN CourseOfferingCreditCardRefundFees
            NATURAL FULL OUTER JOIN CourseOfferingRedemptionRegistrationFees
            GROUP BY offering_launch_date, course_id
        ),
        ManagerNetRegistrationFees AS (
            SELECT manager_id, SUM(f.net_registration_fees) AS net_registration_fees
            FROM Managers
            NATURAL LEFT OUTER JOIN ManagerCourseOfferings
            NATURAL LEFT OUTER JOIN CourseOfferingNetRegistrationFees f
            GROUP BY manager_id
        ),

        /* top course offering titles */
        ManagerCourseOfferingRankedByFees AS (
            SELECT manager_id, course_id, offering_launch_date,
                RANK() OVER (PARTITION BY manager_id ORDER BY f.net_registration_fees DESC) AS course_offering_rank
            FROM ManagerCourseOfferings NATURAL JOIN CourseOfferingNetRegistrationFees f
        ),
        ManagerTopCourseOfferingTitles AS (
            SELECT manager_id, ARRAY_AGG(course_title) top_course_offering_titles
            FROM Managers
            NATURAL LEFT OUTER JOIN (ManagerCourseOfferingRankedByFees NATURAL JOIN Courses)
            WHERE course_offering_rank = 1
            GROUP BY manager_id
        )

        /* oh yea everything come together */
        SELECT m.manager_name,
               COALESCE(ca.num_course_areas, 0),
               COALESCE(co.num_course_offerings, 0),
               COALESCE(f.net_registration_fees, 0),
               COALESCE(t.top_course_offering_titles, '{}')
        FROM Managers
            NATURAL JOIN ManagerNames m
            NATURAL LEFT OUTER JOIN(
                ManagerNumCourseAreas ca
                NATURAL JOIN ManagerNumCourseOfferings co
                NATURAL JOIN ManagerNetRegistrationFees f
                NATURAL JOIN ManagerTopCourseOfferingTitles t
            )
        ORDER BY m.manager_name ASC
    );
END;
$$ LANGUAGE plpgsql;

/*
    29. view_summary_report: This routine is used to view a monthly summary report of the company's sales and expenses for a specified number of months.
    The input to the routine is a number of months (say N) and
    the routine returns a table of records consisting of the following information for each of the last N months (starting from the current month):
        month and year,
        total salary paid for the month,
        total amount of sales of course packages for the month,
        total registration fees paid via credit card payment for the month,
        total amount of refunded registration fees (due to cancellations) for the month, and
        total number of course registrations via course package redemptions for the month.
    For example, if the number of specified months is 3 and the current month is January 2021, the output will consist of one record for each of the following three months: January 2021, December 2020, and November 2020.
*/
DROP FUNCTION IF EXISTS view_summary_report CASCADE;
CREATE OR REPLACE FUNCTION view_summary_report (
    N INTEGER
)
RETURNS TABLE (
    mm                       INTEGER,
    yyyy                     INTEGER,
    salary_paid              DEC(64, 2),
    course_package_sales     DEC(64, 2),
    reg_fees_via_credit_card DEC(64, 2),
    reg_fees_refunded        DEC(64, 2),
    course_reg_redeemed      INTEGER
)
AS $$
DECLARE
    mm_count INTEGER;
    cur_date DATE;
BEGIN
    IF N IS NULL OR N <= 0
    THEN
        RAISE EXCEPTION 'Number of months supplied to generate monthly summary report for must be an integer more than 0.';
    END IF;

    mm_count := 0;
    cur_date := CURRENT_DATE;
    LOOP
        EXIT WHEN mm_count = N;

        SELECT EXTRACT(MONTH FROM cur_date) INTO mm;
        SELECT EXTRACT(YEAR FROM cur_date) INTO yyyy;

        /* DATE_TRUNC('month', ...) gives the first day of the month e.g. 2020-04-01 (1st Apr) */
        /* the year is preserved in the result, so no need to do DATE_TRUNC('year', ...) */

        SELECT COALESCE(SUM(p.payslip_amount), 0.00) INTO salary_paid
        FROM PaySlips p
        WHERE DATE_TRUNC('month', p.payslip_date) = DATE_TRUNC('month', cur_date);

        SELECT COALESCE(SUM(cp.package_price), 0.00) INTO course_package_sales
        FROM Buys b
        NATURAL JOIN CoursePackages cp
        WHERE DATE_TRUNC('month', b.buy_timestamp) = DATE_TRUNC('month', cur_date);

        SELECT COALESCE(SUM(co.offering_fees), 0.00) INTO reg_fees_via_credit_card
        FROM Registers r
        NATURAL JOIN CourseOfferings co
        WHERE DATE_TRUNC('month', r.register_timestamp) = DATE_TRUNC('month', cur_date);

        SELECT COALESCE(SUM(c.cancel_refund_amount), 0.00) INTO reg_fees_refunded
        FROM Cancels c
        WHERE DATE_TRUNC('month', c.cancel_timestamp) = DATE_TRUNC('month', cur_date);

        SELECT COUNT(*) INTO course_reg_redeemed
        FROM Redeems r
        WHERE DATE_TRUNC('month', r.redeem_timestamp) = DATE_TRUNC('month', cur_date) AND NOT r.redeem_cancelled;

        mm_count := mm_count + 1;
        cur_date := cur_date - INTERVAL '1 month';

        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

/*Create view for status of course package*/
CREATE OR REPLACE VIEW package_status AS
SELECT b.customer_id, 
    b.buy_timestamp, 
    (SELECT 
	  CASE 
      WHEN b.buy_num_remaining_redemptions > 0 THEN 'Active'
      WHEN EXISTS(
        SELECT redeem_timestamp 
        FROM Redeems r
        NATURAL JOIN Buys b
        NATURAL JOIN Sessions s
        WHERE s.session_date > CURRENT_DATE + 7
        ) THEN 'Partially Active'
      ELSE 'Inactive'
    END) as Status
FROM Buys b
GROUP BY customer_id, buy_timestamp;
/*Create a view for checking if the status is fully booked*/
CREATE OR REPLACE VIEW status_view AS
SELECT s.session_id, s.course_id, s.offering_launch_date, (
    SELECT 
    CASE 
        WHEN r.room_seating_capacity = (
                SELECT COUNT(*)
                FROM Registers res
                WHERE res.session_id = s.session_id 
                AND res.course_id = red.course_id
                AND res.course_id = s.course_id 
                AND res.offering_launch_date = s.offering_launch_date
            )
        THEN 'Fully Booked'
        ELSE 'Available'
    END
    FROM Redeems red
)
FROM Sessions s JOIN Rooms r
ON s.room_id = r.room_id;
    

