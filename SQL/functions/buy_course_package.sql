/*
This routine is used when a customer requests to purchase a course package.
The inputs to the routine include the customer and course package identifiers.
If the purchase transaction is valid, the routine will process the purchase with the necessary updates (e.g., payment).

Design decision: Add credit card number as input parameter because a customer can have multiple credit cards.
*/
DROP FUNCTION IF EXISTS buy_course_package;
CREATE OR REPLACE FUNCTION buy_course_package (
    r_customer_id         INTEGER,
    r_package_id          INTEGER
) RETURNS VOID
/* Question: Anything we need to return? */
AS $$
DECLARE
    package_sale_start_date         DATE;
    package_sale_end_date           DATE;
    package_num_free_registrations  INTEGER;
    r_credit_card_cvv               CHAR(3);
    r_credit_card_number            CHAR(16);
BEGIN
    SELECT credit_card_number INTO r_credit_card_number
    FROM Owns o
    WHERE o.customer_id = r_customer_id 
    AND o.own_from_date >= ALL(
        SELECT own_from_date
        FROM Owns
        WHERE customer_id = r_customer_id
    );
    
    IF r_credit_card_number IS NULL THEN
        RAISE EXCEPTION 'There is no credit card found';
    END IF;

    SELECT credit_card_cvv INTO r_credit_card_cvv FROM CreditCards WHERE credit_card_number = r_credit_card_number;

    /*Do buying here with CVV and Credit Card number*/

    SELECT p.package_sale_start_date, p.package_sale_end_date, p.package_num_free_registrations
        INTO package_sale_start_date, package_sale_end_date, package_num_free_registrations
    FROM CoursePackages p
    WHERE p.package_id = r_package_id;

    IF CURRENT_DATE < package_sale_end_date OR package_sale_end_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'This package is no longer for sale.';
    END IF;

    INSERT INTO Buys(buy_date, buy_num_remaining_redemptions, package_id, customer_id, credit_card_number)
    VALUES (CURRENT_DATE, package_num_free_registrations, r_package_id, r_customer_id, r_credit_card_number);
END;
$$ LANGUAGE plpgsql;
