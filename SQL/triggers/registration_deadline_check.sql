-- Registration deadline 10 days before lesson start
CREATE OR REPLACE FUNCTION registration_deadline_check() RETURNS TRIGGER AS $$
    DECLARE

    BEGIN
        
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER registration_deadline_trigger
BEFORE INSERT OR UPDATE ON Registers
FOR EACH ROW EXECUTE FUNCTION registration_deadline_check();