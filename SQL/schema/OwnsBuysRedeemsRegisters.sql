DROP TABLE IF EXISTS Owns CASCADE;
CREATE TABLE Owns (
    customer_id INTEGER NOT NULL REFERENCES Customers,
    credit_card_number CHAR(16) NOT NULL REFERENCES CreditCards,
    own_from_date TIMESTAMP NOT NULL,
    PRIMARY KEY(customer_id, credit_card_number)
);

DROP TABLE IF EXISTS Buys CASCADE;
CREATE TABLE Buys (
    buy_date TIMESTAMP PRIMARY KEY NOT NULL,
    buy_num_remaining_redemptions INTEGER NOT NULL,
    package_id INTEGER NOT NULL REFERENCES CoursePackages,
    customer_id INTEGER NOT NULL,
    credit_card_number CHAR(16) NOT NULL,

    CHECK(buy_num_remaining_redemptions >= 0),
    FOREIGN KEY(customer_id, credit_card_number) REFERENCES Owns (customer_id, credit_card_number)
);

DROP TABLE IF EXISTS Redeems CASCADE;
CREATE TABLE Redeems (
    redeem_date TIMESTAMP PRIMARY KEY NOT NULL,
    customer_id INTEGER NOT NULL,
    package_id INTEGER NOT NULL,
    session_id INTEGER NOT NULL,
    offering_launch_date DATE NOT NULL,
    course_id INTEGER NOT NULL,

    FOREIGN KEY(session_id, offering_launch_date, course_id) REFERENCES Sessions(session_id, offering_launch_date, course_id)
);

DROP TABLE IF EXISTS Registers CASCADE;
CREATE TABLE Registers (
    register_date TIMESTAMP PRIMARY KEY NOT NULL,
    customer_id INTEGER NOT NULL,
    credit_card_number CHAR(16) NOT NULL,
    session_id INTEGER NOT NULL,
    offering_launch_date DATE NOT NULL,
    course_id INTEGER NOT NULL,

    FOREIGN KEY(session_id, offering_launch_date, course_id) REFERENCES Sessions(session_id, offering_launch_date, course_id),
    FOREIGN KEY(customer_id, credit_card_number) REFERENCES Owns (customer_id, credit_card_number)
);


