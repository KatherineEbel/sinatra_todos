-- CREATE DATABASE todos;

CREATE TABLE lists (
    id serial PRIMARY KEY,
    name varchar(255) NOT NULL UNIQUE CHECK ( length(name) BETWEEN 1 AND 50)
);

CREATE TABLE todos (
    id serial PRIMARY KEY,
    name varchar(255) NOT NULL UNIQUE CHECK ( length(name) BETWEEN 1 AND 50),
    completed boolean NOT NULL DEFAULT false,
    list_id int NOT NULL REFERENCES lists(id) ON DELETE CASCADE
);
