/*Create a view for checking if the status is fully booked*/
CREATE OR REPLACE VIEW status_view AS
SELECT * 
FROM Sessions s NATURAL JOIN Rooms r
WHERE r.room_seating_capacity = (
    SELECT COUNT(*)
    FROM Registers re
    WHERE re.session_id = s.session_id
    AND re.course_id = s.course_id
    AND re.offering_launch_date = s.offering_launch_date
    )

