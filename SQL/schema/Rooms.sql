DROP TABLE IF EXISTS Rooms CASCADE;
CREATE TABLE Rooms (
    room_id INTEGER PRIMARY KEY,
    location TEXT UNIQUE NOT NULL,
    seating_capacity INTEGER NOT NULL,

    CHECK(seating_capacity >= 0)
);
