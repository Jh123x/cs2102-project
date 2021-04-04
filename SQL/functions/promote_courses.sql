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
*/
CREATE OR REPLACE FUNCTION promote_courses()
RETURNS TABLE(customer_id INTEGER, customer_name TEXT,
course_area TEXT, course_id INTEGER, course_title TEXT, offering_launch_date DATE,
registration_deadline DATE, fees DEC(64,2))
AS $$
BEGIN

END;
$$ LANGUAGE plpgsql;