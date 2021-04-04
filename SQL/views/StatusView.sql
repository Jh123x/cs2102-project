/*Create a view for checking if the status is fully booked*/
CREATE OR REPLACE VIEW status_view AS
SELECT s.session_id, s.course_id, s.offering_launch_date, (
    SELECT 
    CASE 
        WHEN r.room_seating_capacity = (
                SELECT COUNT(*)
                FROM Registers res
                WHERE res.session_id = s.session_id 
                AND res.course_id = red.course_id
                AND res.course_id = s.course_id 
                AND res.offering_launch_date = s.offering_launch_date
            )
        THEN 'Fully Booked'
        ELSE 'Available'
    END
    FROM Redeems red
)
FROM Sessions s JOIN Rooms r
ON s.room_id = r.room_id;
    
