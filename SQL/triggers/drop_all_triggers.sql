/*
    Update this file using this command:
    grep -RihoP '(?<=create )trigger .+' | awk '{print "DROP", $1, "IF EXISTS", $2, "CASCADE"}' | sed 's/$/;/' && grep -RihoP '(function|procedure) .+(?=\()' | awk '{print "DROP", $1, "IF EXISTS", $2, "CASCADE"}' | sed 's/$/;/' | uniq
*/

DROP TRIGGER IF EXISTS customer_redeems_trigger CASCADE;
DROP TRIGGER IF EXISTS update_update_date_trigger CASCADE;
DROP TRIGGER IF EXISTS update_others_date_trigger CASCADE;
DROP TRIGGER IF EXISTS customer_redeems_trigger CASCADE;
DROP TRIGGER IF EXISTS customer_register_trigger CASCADE;
DROP TRIGGER IF EXISTS admin_check_trigger CASCADE;
DROP TRIGGER IF EXISTS manager_check_trigger CASCADE;
DROP TRIGGER IF EXISTS instructor_check_trigger CASCADE;
DROP TRIGGER IF EXISTS no_delete_employee_trigger CASCADE;
DROP TRIGGER IF EXISTS part_time_insert_trigger CASCADE;
DROP TRIGGER IF EXISTS full_time_insert_trigger CASCADE;
DROP TRIGGER IF EXISTS not_more_than_30_trigger CASCADE;
DROP TRIGGER IF EXISTS redemption_check_trigger CASCADE;
DROP TRIGGER IF EXISTS session_collision_trigger CASCADE;
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
