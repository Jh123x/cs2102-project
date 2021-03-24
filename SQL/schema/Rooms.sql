DROP TABLE IF EXISTS Rooms CASCADE;
CREATE TABLE Rooms (
    rid Integer Primary key,
    location Text UNIQUE NOT NULL,
    seating_capacity Integer,
    check(seating_capacity > 0),
);