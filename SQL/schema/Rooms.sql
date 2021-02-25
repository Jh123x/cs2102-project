CREATE TABLE IF NOT EXISTS ROOMS (
    rid Integer Primary key,
    location Text,
    seating_capacity Integer,
    check(seating_capacity > 0),
    unique(location)
);