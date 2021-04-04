/*
This routine is used when a customer requests to purchase a course package.
The inputs to the routine include the customer and course package identifiers.
If the purchase transaction is valid, the routine will process the purchase with the necessary updates (e.g., payment).

Design decision: Add credit card number as input parameter because a customer can have multiple credit cards.
*/
CREATE OR REPLACE FUNCTION buy_course_package (
    customer_id         INTEGER,
    credit_card_number  CHAR(16),
    package_id          INTEGER
) RETURNS VOID
/* Question: Anything we need to return? */
AS $$
DECLARE
    package_sale_start_date         DATE;
    package_sale_end_date           DATE;
    package_num_free_registrations  INTEGER;
BEGIN
    IF credit_card_cvv NOT IN
        (SELECT credit_card_number FROM Owns o WHERE o.customer_id = customer_id) THEN
        RAISE EXCEPTION 'This credit card does not belong to this customer.';
    END IF;

    SELECT p.package_sale_start_date, p.package_sale_end_date, p.package_num_free_registrations
        INTO package_sale_start_date, package_sale_end_date, package_num_free_registrations
    FROM CoursePackages p
    WHERE p.package_id = package_id;

    IF CURRENT_DATE < package_sale_end_date OR package_sale_end_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'This package is no longer for sale.';
    END IF;

    INSERT INTO Buys(buy_date, buy_num_remaining_redemptions, package_id, customer_id, credit_card_number)
    VALUES (CURRENT_DATE, package_num_free_registrations, package_id, customer_id, credit_card_number);
END;
$$ LANGUAGE plpgsql;
