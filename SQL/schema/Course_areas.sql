drop table if exists Course_areas cascade;

create table Course_areas (
    name TEXT PRIMARY KEY,
    manager_id INTEGER REFERENCES Managers,
);