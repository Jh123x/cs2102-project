DROP TABLE IF EXISTS Owns CASCADE;
CREATE TABLE Owns (
    cust_id INTEGER REFERENCES Customers,
    number CHAR(16) REFERENCES CreditCards,
    from_date DATE NOT NULL,
    PRIMARY KEY(cust_id, number)
);
DROP TABLE IF EXISTS Buys CASCADE;
CREATE TABLE Buys (
    date TIMESTAMP PRIMARY KEY,
    num_remaining_redemptions INTEGER NOT NULL,
    package_id INTEGER NOT NULL REFERENCES CoursePackages,
    cust_id INTEGER NOT NULL,
    number CHAR(16),
    CHECK(num_remaining_redemptions >= 0),
    FOREIGN KEY(cust_id, number) REFERENCES Owns (cust_id, number)
);
DROP TABLE IF EXISTS Redeems CASCADE;
CREATE TABLE Redeems (
    date TIMESTAMP PRIMARY KEY,
    sid INTEGER REFERENCES Sessions(sid),
    cust_id INTEGER NOT NULL,
    package_id INTEGER NOT NULL
);
DROP TABLE IF EXISTS Registers CASCADE;
CREATE TABLE Registers (
    date TIMESTAMP PRIMARY KEY,
    sid INTEGER NOT NULL REFERENCES Sessions(sid),
    cust_id INTEGER NOT NULL,
    number CHAR(16) NOT NULL,
    FOREIGN KEY(cust_id, number) REFERENCES Owns (cust_id, number)
);