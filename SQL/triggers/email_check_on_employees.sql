CREATE OR REPLACE FUNCTION email_check_on_employees() RETURNS TRIGGER AS $$
DECLARE
    counter INTEGER;
BEGIN
    SELECT COUNT(*) INTO counter FROM NEW WHERE NEW.email LIKE %@%;
    IF (counter = 0) THEN 
        RETURN NULL;
    ELSE 
        RETURN NEW;
    ENDIF;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER email_check_on_employees_trigger
BEFORE INSERT OR UPDATE ON Employees
FOR EACH ROW EXECUTE FUNCTION check_email_on_employees();