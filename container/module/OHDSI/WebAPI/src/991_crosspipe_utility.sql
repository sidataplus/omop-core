-- NB: This SQL is not used in the OHDSI/WebAPI project, but is customized for the use with CrossPipe.

CREATE SCHEMA crosspipe;

CREATE TABLE crosspipe.status (
    status_id int NOT NULL,
    status_name VARCHAR (255) NOT NULL,
    status_value int NOT NULL
);

INSERT INTO crosspipe.status( status_id, status_name, status_value) VALUES (1, 'Data was written', 0);