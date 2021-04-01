DROP TABLE IF EXISTS Rooms CASCADE;
CREATE TABLE Rooms (
    room_id INTEGER PRIMARY KEY,
    room_location TEXT UNIQUE NOT NULL,
    room_seating_capacity INTEGER NOT NULL,

    CHECK(room_seating_capacity >= 0)
);
