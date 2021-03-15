DROP TABLE IF EXISTS Course_areas CASCADE;
create table Course_areas (
    name TEXT PRIMARY KEY,
    manager_id INTEGER REFERENCES Managers,
);