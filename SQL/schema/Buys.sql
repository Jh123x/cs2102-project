DROP TABLE IF EXISTS Buys CASCADE;

CREATE TABLE Buys (
    date DATE PRIMARY KEY,
    num_remaining_redemptions INTEGER NOT NULL,
    sid INTEGER REFERENCES Redeems,
    CHECK(num_remaining_redemptions >= 0)
);