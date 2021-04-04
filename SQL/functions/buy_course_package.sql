/*
    13. buy_course_package: This routine is used when a customer requests to purchase a course package.
    The inputs to the routine include the customer and course package identifiers.
    If the purchase transaction is valid, the routine will process the purchase with the necessary updates (e.g., payment).

    Todo: Need to check if customer has no active/partially active course package first.
*/
DROP FUNCTION IF EXISTS buy_course_package;
CREATE OR REPLACE FUNCTION buy_course_package (
    r_customer_id         INTEGER,
    r_package_id          INTEGER
) RETURNS VOID
AS $$
DECLARE
    package_sale_start_date         DATE;
    package_sale_end_date           DATE;
    package_num_free_registrations  INTEGER;
    r_credit_card_number            CHAR(16);
BEGIN
    /* Select last owned credit card of customer */
    SELECT credit_card_number INTO r_credit_card_number
    FROM Owns o
    WHERE o.customer_id = r_customer_id
    ORDER BY o.own_from_date DESC
    LIMIT 1;
    
    IF r_credit_card_number IS NULL THEN
        RAISE EXCEPTION 'There is no credit card found for customer. Check if customer_id supplied is valid.';
    END IF;

    /* Check if course package is still for sale */
    SELECT cp.package_sale_start_date, cp.package_sale_end_date, cp.package_num_free_registrations
        INTO package_sale_start_date, package_sale_end_date, package_num_free_registrations
    FROM CoursePackages cp
    WHERE cp.package_id = r_package_id;

    IF CURRENT_DATE < package_sale_start_date THEN
        RAISE EXCEPTION 'This package is not for sale yet.';
    ELSIF package_sale_end_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'This package is no longer for sale.';
    END IF;

    /* Do buying here with Credit Card number */
    INSERT INTO Buys
    (buy_date, buy_num_remaining_redemptions, package_id, customer_id, credit_card_number)
    VALUES
    (CURRENT_DATE, package_num_free_registrations, r_package_id, r_customer_id, r_credit_card_number);
END;
$$ LANGUAGE plpgsql;
