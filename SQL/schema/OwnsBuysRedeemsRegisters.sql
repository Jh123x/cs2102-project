DROP TABLE IF EXISTS Owns CASCADE;
DROP TABLE IF EXISTS Buys CASCADE;
DROP TABLE IF EXISTS Redeems CASCADE;
DROP TABLE IF EXISTS Registers CASCADE;

CREATE TABLE Owns (
    cust_id INTEGER REFERENCES Customers,
    number CHAR(16) REFERENCES Credit_cards,
    PRIMARY KEY(cust_id, number)
);

CREATE TABLE Buys (
    date TIMESTAMP PRIMARY KEY,
    num_remaining_redemptions INTEGER NOT NULL,
    package_id INTEGER REFERENCES Course_packages,
    cust_id INTEGER,
    number CHAR(16),
    CHECK(num_remaining_redemptions >= 0),
    FOREIGN KEY(cust_id, number) REFERENCES Owns (cust_id, number)
);

CREATE TABLE Redeems (
    date TIMESTAMP PRIMARY KEY,
    sid INTEGER REFERENCES Sessions,
    cust_id INTEGER,
    number CHAR(16),
    package_id INTEGER,
    FOREIGN KEY(cust_id, number, package_id) REFERENCES Buys (cust_id, number, package_id)
);

CREATE TABLE Registers (
    date TIMESTAMP PRIMARY KEY,
    sid INTEGER REFERENCES Sessions,
    cust_id INTEGER,
    number CHAR(16),
    FOREIGN KEY(cust_id, number) REFERENCES Owns (cust_id, number)
);