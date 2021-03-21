-- Check if the email is valid --
CREATE OR REPLACE FUNCTION email_check_on_table() RETURNS TRIGGER AS $$
BEGIN
    IF (email LIKE %@%) THEN 
        RETURN NULL;
    ELSE 
        RETURN NEW;
    ENDIF;
END;
$$ LANGUAGE plpgsql;


-- Add the trigger to employees -- 
CREATE TRIGGER email_check_on_employees_trigger
BEFORE INSERT OR UPDATE ON Employees
FOR EACH ROW EXECUTE FUNCTION email_check_on_table();

-- Add the trigger to customers --
CREATE TRIGGER email_check_on_customers_trigger
BEFORE INSERT OR UPDATE ON Customers
FOR EACH ROW EXECUTE FUNCTION email_check_on_table();
