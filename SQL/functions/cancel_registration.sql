/*
    20. cancel_registration: This routine is used when a customer requests to cancel a registered course session.
    The inputs to the routine include the following:
        customer identifier, and
        course offering identifier.
    If the cancellation request is valid, the routine will process the request with the necessary updates.
*/
DROP FUNCTION IF EXISTS cancel_registration CASCADE;
CREATE OR REPLACE FUNCTION cancel_registration (
    customer_id             INTEGER,
    course_id               INTEGER,
    offering_launch_date    DATE
) RETURNS VOID
AS $$
DECLARE
    enroll_date         DATE;
    session_id          INTEGER;
    enrolment_table     TEXT;
    offering_fees       DEC(64, 2);
    session_date        DATE;

    refund_amt          DEC(64,2);
    package_credit      INTEGER;
BEGIN
    /* Check for NULLs in arguments */
    IF customer_id IS NULL
        OR course_id IS NULL
        OR offering_launch_date IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to cancel_registration() cannot contain NULL values.';
    END IF;

    SELECT e.enroll_date, e.session_id, e.table_name INTO enroll_date, session_id, enrolment_table
    FROM Enrolment e
    WHERE customer_id = e.customer_id AND course_id = e.course_id AND offering_launch_date = e.offering_launch_date;

    IF enroll_date IS NULL THEN
        RAISE EXCEPTION 'Customer did not register for this course offering.';
    END IF;

    SELECT c.offering_fees, s.session_date INTO offering_fees, session_date
    FROM Sessions s NATURAL JOIN CourseOfferings c
    WHERE s.course_id = course_id AND s.offering_launch_date = offering_launch_date AND s.session_id = session_id;

    IF enrolment_table = 'registers' THEN
        UPDATE Registers r
        SET r.register_cancelled = TRUE
        WHERE r.register_timestamp = enroll_date;

        IF CURRENT_DATE <= session_date - interval '7 days' THEN
            refund_amt := 0.90 * offering_fees;
        ELSE
            refund_amt := 0;
        END IF;

        INSERT INTO Cancels(cancel_date, cancel_refund_amt, cancel_package_credit,
                            course_id, session_id, offering_launch_date, customer_id)
        VALUES (CURRENT_DATE, refund_amt, NULL, course_id, session_id, offering_launch_date, customer_id);
    ELSE
        UPDATE Redeems r
        SET r.redeem_cancelled = TRUE
        WHERE r.redeem_timestamp = enroll_date;

        IF CURRENT_DATE <= session_date - interval '7 days' THEN
            package_credit := 1;
        ELSE
            package_credit := 0;
        END IF;

        INSERT INTO Cancels(cancel_date, cancel_refund_amt, cancel_package_credit,
                            course_id, session_id, offering_launch_date, customer_id)
        VALUES (CURRENT_DATE, NULL, package_credit, course_id, session_id, offering_launch_date, customer_id);
    END IF;
END;
$$ LANGUAGE plpgsql;
