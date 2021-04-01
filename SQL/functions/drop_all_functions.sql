/*
    Update this file using this command:
    grep -RihoP '(function|procedure) .+(?=\()' | awk '{print "DROP", $1, "IF EXISTS", $2, "CASCADE"}' | sed 's/$/;/'
*/

DROP PROCEDURE IF EXISTS add_course CASCADE;
DROP PROCEDURE IF EXISTS add_course_offering CASCADE;
DROP PROCEDURE IF EXISTS add_course_package CASCADE;
DROP FUNCTION IF EXISTS add_customer CASCADE;
DROP FUNCTION IF EXISTS add_employee CASCADE;
DROP FUNCTION IF EXISTS find_instructors CASCADE;
DROP FUNCTION IF EXISTS get_available_instructors CASCADE;
DROP FUNCTION IF EXISTS pay_salary CASCADE;
DROP PROCEDURE IF EXISTS remove_employee CASCADE;
DROP PROCEDURE IF EXISTS update_credit_card CASCADE;
DROP PROCEDURE IF EXISTS update_instructor CASCADE;
