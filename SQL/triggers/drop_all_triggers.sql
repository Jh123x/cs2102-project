/*
    Update this file using this command:
    grep -RihoPz '(?s)create (constraint )?trigger .+?\n.+?\n' --exclude drop* | awk 'NF>1{printf "DROP TRIGGER IF EXISTS %s ", $NF; if (NF != 0) {getline; printf "ON %s CASCADE;\n", $NF;}}' && grep -RihoP '(function|procedure) .+(?=\()' | awk '{print "DROP", $1, "IF EXISTS", $2, "CASCADE;"}' | uniq
*/

DROP TRIGGER IF EXISTS credit_card_expiry ON Registers CASCADE;
DROP TRIGGER IF EXISTS credit_card_expiry ON Buys CASCADE;
DROP TRIGGER IF EXISTS credit_card_expiry ON Owns CASCADE;
DROP TRIGGER IF EXISTS credit_card_expiry_check ON CreditCards CASCADE;
DROP TRIGGER IF EXISTS session_duration_check_trigger ON Sessions CASCADE;
DROP TRIGGER IF EXISTS session_date_check_trigger ON Sessions CASCADE;
DROP TRIGGER IF EXISTS customer_cancels_trigger ON Cancels CASCADE;
DROP TRIGGER IF EXISTS customer_redemption_trigger ON Redeems CASCADE;
DROP TRIGGER IF EXISTS update_update_date_trigger ON Sessions CASCADE;
DROP TRIGGER IF EXISTS update_others_date_trigger ON Sessions CASCADE;
DROP TRIGGER IF EXISTS customers_total_participation ON Customers CASCADE;
DROP TRIGGER IF EXISTS credit_cards_key_constraint ON CreditCards CASCADE;
DROP TRIGGER IF EXISTS credit_cards_total_participation_constraint ON CreditCards CASCADE;
DROP TRIGGER IF EXISTS customers_total_participation_constraint ON Owns CASCADE;
DROP TRIGGER IF EXISTS credit_cards_key_constraint ON Owns CASCADE;
DROP TRIGGER IF EXISTS customer_redeems_trigger ON Redeems CASCADE;
DROP TRIGGER IF EXISTS customer_register_trigger ON Registers CASCADE;
DROP TRIGGER IF EXISTS admin_check_trigger ON Administrators CASCADE;
DROP TRIGGER IF EXISTS manager_check_trigger ON Managers CASCADE;
DROP TRIGGER IF EXISTS instructor_check_trigger ON Instructors CASCADE;
DROP TRIGGER IF EXISTS no_delete_employee_trigger ON Employees CASCADE;
DROP TRIGGER IF EXISTS part_time_insert_trigger ON PartTimeEmployees CASCADE;
DROP TRIGGER IF EXISTS full_time_insert_trigger ON FullTimeEmployees CASCADE;
DROP TRIGGER IF EXISTS not_more_than_30_trigger ON Sessions CASCADE;
DROP TRIGGER IF EXISTS redemption_check_trigger ON Redeems CASCADE;
DROP TRIGGER IF EXISTS session_collision_trigger ON Sessions CASCADE;
DROP FUNCTION IF EXISTS customer_cancels_check CASCADE;
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
DROP FUNCTION IF EXISTS get_credit_card_expiry CASCADE;
