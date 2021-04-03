/*
This routine is used to retrieve the availability information of instructors who could be assigned to teach a specified course.
The inputs to the routine include the following: course identifier, start date, and end date.
The routine returns a table of records consisting of the following information:
    employee identifier, name, total number of teaching hours that the instructor has been assigned for this month,
    day (which is within the input date range [start date, end date]),
    and an array of the available hours for the instructor on the specified day.
The output is sorted in ascending order of employee identifier and day,
    and the array entries are sorted in ascending order of hour.
*/

CREATE OR REPLACE FUNCTION get_available_instructors (
    course_id INTEGER,
    start_date DATE,
    end_date DATE
)
RETURNS TABLE (
    employee_id INTEGER,
    name TEXT,
    total_teaching_hours INTEGER,
    day DATE,
    available_hours TIMESTAMP[]
) ORDER BY employee_id ASC, day ASC AS $$
DECLARE
    curs CURSOR FOR (
        SELECT e.employee_id, e.employee_name
        FROM Employees e
        NATURAL JOIN Specializes s
        NATURAL JOIN Courses c
    );
    r RECORD;
    cur_date DATE;
    hour INTEGER;
    work_hours INTEGER[] := ARRAY[9,10,11,14,15,16,17];

BEGIN
    OPEN curs;
    LOOP
        FETCH curs INTO r;
        EXIT WHEN NOT FOUND;

        cur_date := start_date;
        LOOP
            EXIT WHEN cur_date > end_date;

            day := cur_date;
            employee_id := r.employee_id;
            name := r.name;

            /* requirement: total number of teaching hours that the instructor has been assigned for this month */
            /* assuming that this month refers to the day in this row */
            SELECT COALESCE(SUM(end_time - start_time), 0) INTO total_teaching_hours FROM Sessions s
                    WHERE s.instructor_id = r.employee_id
                    AND EXTRACT(MONTH FROM s.session_date) == EXTRACT(MONTH FROM cur_date);
            available_hours := '{}';

            FOREACH hour IN ARRAY work_hours LOOP
                IF new_instructor_employee_id IN
                    (SELECT employee_id FROM find_instructors(course_id, cur_date, hour)) THEN
                    available_hours := array_append(available_hours, hour);
                END IF;
            END LOOP;

            IF array_length(available_hours, 1) > 0 THEN
                RETURN NEXT;
            END IF;

            cur_date := cur_date + interval '1 day';
        END LOOP;
    END LOOP;
    CLOSE curs;
END;
$$ LANGUAGE plpgsql;
