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

CREATE OR REPLACE FUNCTION view_summary_report (
    N INTEGER
)
RETURNS TABLE (
    mm                  INTEGER,
    yyyy                INTEGER,
    salary_paid         DEC(64, 2),
    packages_sold       INTEGER,
    reg_fees_via_ccard  DEC(64, 2),
    refunded_fees       DEC(64, 2),
    regs_via_redeem     INTEGER
)
AS $$
DECLARE
    mm_count INTEGER;
    cur_date DATE;
BEGIN
    mm_count := 0;
    cur_date := CURRENT_DATE;
    LOOP
        EXIT WHEN mm_count = N;

        SELECT EXTRACT(MONTH FROM cur_date) into mm;
        SELECT EXTRACT(YEAR FROM cur_date) into yyyy;

        /* DATE_TRUNC gives the first day of the month */
        /* the year is preserved in the result, so no need to do DATE_TRUNC('year', ...) */

        SELECT SUM(payslip_amount) into salary_paid
        FROM PaySlips
        WHERE DATE_TRUNC('month', payslip_date) = DATE_TRUNC('month', cur_date);

        SELECT COUNT(*) into packages_sold
        FROM Buys
        WHERE DATE_TRUNC('month', buy_date) = DATE_TRUNC('month', cur_date);

        SELECT SUM(offering_fees) into reg_fees_via_ccard
        FROM Registers NATURAL JOIN CourseOfferings
        WHERE DATE_TRUNC('month', cancel_date) = DATE_TRUNC('month', cur_date);

        SELECT SUM(cancel_refund_amt) into refunded_fees
        FROM Cancels
        WHERE DATE_TRUNC('month', cancel_date) = DATE_TRUNC('month', cur_date);

        SELECT COUNT(*) into regs_via_redeem
        FROM Redeems
        WHERE DATE_TRUNC('month', cancel_date) = DATE_TRUNC('month', cur_date);

        mm_count := mm_count + 1;
        cur_date := cur_date - interval '1 month';
    END LOOP;
END;
$$ LANGUAGE plpgsql;
