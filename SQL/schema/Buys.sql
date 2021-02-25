CREATE TABLE IF NOT EXISTS Buys(
    date DATE primary key,
    num_remaining_redemptions INTEGER not null,
    sid INTEGER REFERENCES Sessions,
    check(num_remaining_redemptions)
)