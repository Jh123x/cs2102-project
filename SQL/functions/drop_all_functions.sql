/*
    Update this file using this command:
    grep -RihoP '(function|procedure) .+(?=\()' --exclude drop* | awk '{print "DROP", $1, "IF EXISTS", $2, "CASCADE;"}'
*/
DROP FUNCTION IF EXISTS add_course CASCADE;
DROP FUNCTION IF EXISTS add_course_offering CASCADE;
DROP FUNCTION IF EXISTS add_course_package CASCADE;
DROP FUNCTION IF EXISTS add_customer CASCADE;
DROP FUNCTION IF EXISTS add_employee CASCADE;
DROP FUNCTION IF EXISTS add_session CASCADE;
DROP FUNCTION IF EXISTS buy_course_package CASCADE;
DROP FUNCTION IF EXISTS cancel_registration CASCADE;
DROP FUNCTION IF EXISTS find_instructors CASCADE;
DROP FUNCTION IF EXISTS find_rooms CASCADE;
DROP FUNCTION IF EXISTS get_offering_num_remaining_seats CASCADE;
DROP FUNCTION IF EXISTS get_available_course_offerings CASCADE;
DROP FUNCTION IF EXISTS get_available_course_packages CASCADE;
DROP FUNCTION IF EXISTS get_session_num_remaining_seats CASCADE;
DROP FUNCTION IF EXISTS get_available_course_sessions CASCADE;
DROP FUNCTION IF EXISTS get_available_instructors CASCADE;
DROP FUNCTION IF EXISTS get_available_rooms CASCADE;
DROP FUNCTION IF EXISTS customer_has_active_ish_course_package CASCADE;
DROP FUNCTION IF EXISTS get_customer_active_ish_course_package CASCADE;
DROP FUNCTION IF EXISTS customer_has_course_packages CASCADE;
DROP FUNCTION IF EXISTS get_customer_course_packages CASCADE;
DROP FUNCTION IF EXISTS has_active_or_partially_active_course_package CASCADE;
DROP FUNCTION IF EXISTS get_my_course_package CASCADE;
DROP FUNCTION IF EXISTS get_my_registrations CASCADE;
DROP FUNCTION IF EXISTS pay_salary CASCADE;
DROP FUNCTION IF EXISTS get_offering_num_enrolled CASCADE;
DROP FUNCTION IF EXISTS popular_courses CASCADE;
DROP FUNCTION IF EXISTS promote_courses CASCADE;
DROP FUNCTION IF EXISTS register_session CASCADE;
DROP FUNCTION IF EXISTS is_active_admin CASCADE;
DROP FUNCTION IF EXISTS is_active_manager CASCADE;
DROP FUNCTION IF EXISTS remove_employee CASCADE;
DROP FUNCTION IF EXISTS remove_session CASCADE;
DROP FUNCTION IF EXISTS top_packages CASCADE;
DROP FUNCTION IF EXISTS update_course_session CASCADE;
DROP FUNCTION IF EXISTS update_credit_card CASCADE;
DROP FUNCTION IF EXISTS update_instructor CASCADE;
DROP FUNCTION IF EXISTS update_room CASCADE;
DROP FUNCTION IF EXISTS view_manager_report CASCADE;
DROP FUNCTION IF EXISTS view_summary_report CASCADE;
