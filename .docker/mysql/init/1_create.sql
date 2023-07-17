CREATE DATABASE golang;
USE golang;

CREATE TABLE customers
(
    id    INT PRIMARY KEY,
    value VARCHAR(255)
);

INSERT INTO customers (id, value) VALUES (1, 'Initial Value');
