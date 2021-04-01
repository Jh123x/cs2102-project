/*Create view for status of course package*/
CREATE OR REPLACE VIEW package_status AS
SELECT b.customer_id, 
    b.date, 
    (SELECT 
	 CASE 
      WHEN b.num_remaining_redemptions > 0 THEN 'Active'
      WHEN (
        SELECT COUNT(*) 
        FROM Redeems r JOIN Sessions s 
        ON r.session_id = s.session_id 
        AND r.course_id = s.course_id 
        AND r.launch_date = r.launch_date
        WHERE r.customer_id = b.customer_id 
        AND s.date > CURRENT_DATE
        ) > 0 THEN 'Partially Active'
      ELSE 'Inactive'
    END)
FROM Buys b
GROUP BY customer_id, date;