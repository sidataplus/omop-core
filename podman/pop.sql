-- CREATE SCHEMA webapi

-- CREATE TABLE webapi.source (
--     SOURCE_ID int NOT NULL,
--     SOURCE_NAME VARCHAR (255) NOT NULL,
--     SOURCE_KEY  VARCHAR (50) NOT NULL,
--     SOURCE_CONNECTION VARCHAR (4000) NOT NULL,
--     SOURCE_DIALECT VARCHAR (255) NOT NULL,
--     CONSTRAINT PK_source PRIMARY KEY (source_id) 
-- );

-- CREATE TABLE webapi.source_daimon (
--     source_daimon_id int NOT NULL,
--     source_id int NOT NULL,
--     daimon_type int NOT NULL,
--     table_qualifier  VARCHAR (255) NOT NULL,
--     priority int NOT NULL,
--     CONSTRAINT PK_source_daimon PRIMARY KEY (source_daimon_id) 
-- );


-- remove any previously added database connection configuration data
truncate webapi.source;
truncate webapi.source_daimon;

-- OHDSI CDM source
INSERT INTO webapi.source( source_id, source_name, source_key, source_connection, source_dialect)
VALUES (1, 'OMOP Development under TCEL Funds by SiData', 'DEV_TCEL',
  'jdbc:postgresql://atlas-pg:5432/webtools?user=postgres&password=mypass', 'postgresql');

-- CDM daimon
-- INSERT INTO webapi.source_daimon( source_daimon_id, source_id, daimon_type, table_qualifier, priority) VALUES (1, 1, 0, 'cdm', 0);
INSERT INTO webapi.source_daimon( source_daimon_id, source_id, daimon_type, table_qualifier, priority) VALUES (1, 1, 0, 'webapi', 0);

-- VOCABULARY daimon
-- INSERT INTO webapi.source_daimon( source_daimon_id, source_id, daimon_type, table_qualifier, priority) VALUES (2, 1, 1, 'vocab', 10);
INSERT INTO webapi.source_daimon( source_daimon_id, source_id, daimon_type, table_qualifier, priority) VALUES (2, 1, 1, 'webapi', 10);

-- RESULTS daimon
    /* Under Development */
-- INSERT INTO webapi.source_daimon( source_daimon_id, source_id, daimon_type, table_qualifier, priority) VALUES (3, 1, 2, 'results', 0);
-- INSERT INTO webapi.source_daimon( source_daimon_id, source_id, daimon_type, table_qualifier, priority) VALUES (3, 1, 2, 'webapi', 0);

-- EVIDENCE daimon /* N/A */
-- INSERT INTO webapi.source_daimon( source_daimon_id, source_id, daimon_type, table_qualifier, priority) VALUES (4, 1, 3, 'results', 0);