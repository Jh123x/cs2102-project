/*
    Update this file using this command:
    grep -RihoPz '(?s)(?<=create )trigger .+?\n.+?\n' --exclude drop* | awk 'NF>1{printf "DROP %s IF EXISTS ", $0; if (NF != 0) {getline; printf "ON %s CASCADE;\n", $NF;}}' && grep -RihoP '(function|procedure) .+(?=\()' | awk '{print "DROP", $1, "IF EXISTS", $2, "CASCADE;"}' | uniq
*/
DROP TRIGGER customer_redeems_trigger IF EXISTS ON Redeems CASCADE;
DROP TRIGGER update_update_date_trigger IF EXISTS ON Sessions CASCADE;
DROP TRIGGER update_others_date_trigger IF EXISTS ON Sessions CASCADE;
DROP TRIGGER customer_redeems_trigger IF EXISTS ON Redeems CASCADE;
DROP TRIGGER customer_register_trigger IF EXISTS ON Registers CASCADE;
DROP TRIGGER admin_check_trigger IF EXISTS ON Administrators CASCADE;
DROP TRIGGER manager_check_trigger IF EXISTS ON Managers CASCADE;
DROP TRIGGER instructor_check_trigger IF EXISTS ON Instructors CASCADE;
DROP TRIGGER no_delete_employee_trigger IF EXISTS ON Employees CASCADE;
DROP TRIGGER part_time_insert_trigger IF EXISTS ON PartTimeEmployees CASCADE;
DROP TRIGGER full_time_insert_trigger IF EXISTS ON FullTimeEmployees CASCADE;
DROP TRIGGER not_more_than_30_trigger IF EXISTS ON Sessions CASCADE;
DROP TRIGGER redemption_check_trigger IF EXISTS ON Redeems CASCADE;
DROP TRIGGER session_collision_trigger IF EXISTS ON Sessions CASCADE;
DROP FUNCTION IF EXISTS customer_redeems_check CASCADE;
DROP FUNCTION IF EXISTS check_offering_dates CASCADE;
DROP FUNCTION IF EXISTS customers_total_participation_check CASCADE;
DROP FUNCTION IF EXISTS credit_cards_key_constraint_check CASCADE;
DROP FUNCTION IF EXISTS credit_cards_total_participation_check CASCADE;
DROP FUNCTION IF EXISTS customers_total_participation_check CASCADE;
DROP FUNCTION IF EXISTS credit_cards_key_constraint_check CASCADE;
DROP FUNCTION IF EXISTS customer_session_check CASCADE;
DROP FUNCTION IF EXISTS role_check CASCADE;
DROP FUNCTION IF EXISTS no_deletion_of_employees CASCADE;
DROP FUNCTION IF EXISTS part_full_time_check CASCADE;
DROP FUNCTION IF EXISTS part_time_hour_check CASCADE;
DROP FUNCTION IF EXISTS redeems_check CASCADE;
DROP FUNCTION IF EXISTS session_collision_check CASCADE;
