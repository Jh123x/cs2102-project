/*
    7. get_available_instructors: This routine is used to retrieve the availability information of instructors who could be assigned to teach a specified course.
    The inputs to the routine include the following:
        course identifier,
        start date, and
        end date.
    The routine returns a table of records consisting of the following information:
        employee identifier,
        name,
        total number of teaching hours that the instructor has been assigned for this month,
        day (which is within the input date range [start date, end date]), and
        an array of the available hours for the instructor on the specified day.
    The output is sorted in
        ascending order of employee identifier and
        day, and
        the array entries are sorted in
            ascending order of hour.
*/

DROP FUNCTION IF EXISTS get_available_instructors CASCADE;
CREATE OR REPLACE FUNCTION get_available_instructors (
    course_id_arg INTEGER,
    start_date_arg DATE,
    end_date_arg DATE
)
RETURNS TABLE (
    r_employee_id INTEGER,
    name TEXT,
    total_teaching_hours INTEGER,
    day DATE,
    available_hours INTEGER[]
) AS $$
DECLARE
    /*Remove duplicates in the query as it has alot of duplicates*/
    curs CURSOR FOR (
        SELECT DISTINCT e.employee_id, e.employee_name
        FROM Employees e
        NATURAL JOIN Specializes s
        NATURAL JOIN Courses c
        WHERE c.course_id = course_id_arg
        AND e.employee_join_date <= start_date_arg /*Check if the instructor has already been hired*/
        ORDER BY e.employee_id ASC
    );
    r RECORD;
    cur_date DATE;
    hour INTEGER;
    work_hours INTEGER[] := ARRAY[9,10,11,14,15,16,17];

BEGIN
    /* Check for NULLs in arguments */
    IF course_id_arg IS NULL
        OR start_date_arg IS NULL
        OR end_date_arg IS NULL
    THEN
        RAISE EXCEPTION 'Arguments to get_available_instructors() cannot contain NULL values.';
    ELSIF start_date_arg > end_date_arg THEN
        RAISE EXCEPTION 'Start date should not be later than end date.';
    END IF;

    OPEN curs;
    LOOP
        FETCH curs INTO r;
        EXIT WHEN NOT FOUND;

        cur_date := start_date_arg;
        LOOP
            EXIT WHEN cur_date > end_date_arg;

            day := cur_date;
            r_employee_id := r.employee_id;
            name := r.employee_name;
            available_hours := '{}';

            /* requirement: total number of teaching hours that the instructor has been assigned for this month */
            /* assuming that this month refers to the day in this row */
            SELECT COALESCE(SUM(s.session_end_hour - s.session_start_hour), 0) INTO total_teaching_hours
            FROM Sessions s
                WHERE s.instructor_id = r.employee_id
                    AND EXTRACT(MONTH FROM s.session_date) = EXTRACT(MONTH FROM cur_date);

            FOREACH hour IN ARRAY work_hours LOOP
                IF r_employee_id IN
                    (SELECT employee_id FROM find_instructors(course_id_arg, cur_date, hour)) THEN
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
