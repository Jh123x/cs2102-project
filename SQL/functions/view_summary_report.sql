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
    IF N <= 0 THEN
        RAISE EXCEPTION 'Monthly summary report can only be generated if the number of months supplied is more than 0.';
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
        WHERE DATE_TRUNC('month', b.buy_date) = DATE_TRUNC('month', cur_date);

        SELECT COALESCE(SUM(co.offering_fees), 0.00) INTO reg_fees_via_credit_card
        FROM Registers r
        NATURAL JOIN CourseOfferings co
        WHERE DATE_TRUNC('month', r.register_date) = DATE_TRUNC('month', cur_date);

        SELECT COALESCE(SUM(c.cancel_refund_amt), 0.00) INTO reg_fees_refunded
        FROM Cancels c
        WHERE DATE_TRUNC('month', c.cancel_date) = DATE_TRUNC('month', cur_date);

        SELECT COUNT(*) INTO course_reg_redeemed
        FROM Redeems r
        WHERE DATE_TRUNC('month', r.redeem_date) = DATE_TRUNC('month', cur_date);

        mm_count := mm_count + 1;
        cur_date := cur_date - INTERVAL '1 month';

        RETURN NEXT;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
