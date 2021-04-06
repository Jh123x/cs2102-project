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
        IT is possible that a customer registers or redeems some sessions at the exact same time.
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
            SELECT r.customer_id, r.register_date AS enrol_date, c.course_area_name
            FROM Registers r
            NATURAL JOIN Sessions s
            NATURAL JOIN CourseOfferings co
            NATURAL JOIN Courses c
            WHERE r.register_date IN (
                SELECT r2.register_date
                FROM Registers r2
                WHERE r2.customer_id = r.customer_id
                ORDER BY r2.register_date DESC, c.course_area_name ASC
                LIMIT 3
            )
        ),
        /* Try to find the last 3 sessions redeemed for each customer - this is to identify course areas of interest for each customer */
        LastThreeSessionsRedeemed AS (
            SELECT b.customer_id, r.redeem_date AS enrol_date, c.course_area_name
            FROM Redeems r
            NATURAL JOIN Buys b
            NATURAL JOIN Sessions s
            NATURAL JOIN CourseOfferings co
            NATURAL JOIN Courses c
            WHERE r.redeem_date IN (
                SELECT r2.redeem_date
                FROM Redeems r2
                NATURAL JOIN Buys b2
                WHERE b2.customer_id = b.customer_id
                ORDER BY r2.redeem_date DESC, c.course_area_name ASC
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
                    AND e2.enrol_date >= (NOW() - interval '6 months')
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
