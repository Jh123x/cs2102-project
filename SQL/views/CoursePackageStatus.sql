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