/*
    5. add_course: This routine is used to add a new course.
    The inputs to the routine include the following:
        course title,
        course description,
        course area, and
        duration.
    The course identifier is generated by the system.
*/
DROP FUNCTION IF EXISTS add_course CASCADE;
CREATE OR REPLACE FUNCTION add_course (
    course_title TEXT,
    course_description TEXT,
    course_area_name TEXT,
    course_duration INTEGER
)
RETURNS TABLE (course_id INTEGER) AS $$
DECLARE
    new_course RECORD;
BEGIN
    INSERT INTO Courses
    (course_title, course_description, course_duration, course_area_name)
    VALUES
    (course_title, course_description, course_duration, course_area_name)
    RETURNING * INTO new_course;

    course_id := new_course.course_id;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;
