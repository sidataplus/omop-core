## Forked from: https://github.com/OHDSI/Broadsea-Atlasdb/blob/main/Dockerfile

ARG PASSWORD_METHOD=default

FROM openjdk:8-jre-alpine as builder-image
LABEL stage=intermediate

WORKDIR /tmp

# install the command line tools only used in this intermediate container image builder
RUN apk add git wget

# get the specific tagged release of the WebAPI GitHub repo source code 
RUN git clone https://github.com/OHDSI/WebAPI && cd WebAPI && git checkout "v2.12.0"

# concatenate all the current WebAPI results schema tables ohdisql files into a single file
# - in this order: 1)  DDL, 2) init (populate) sql, and 3) index creation sql
# (ignore any 'impala' or 'hive' dbms ddl files)
WORKDIR /tmp/WebAPI/src/main/resources/ddl/results
# RUN find . -type f -maxdepth 1 -not -regex '.*\(index\|init\|hive\|impala\).*' | xargs cat >/tmp/results_ohdisql.ddl && \
#     find . -maxdepth 1 -type f \( -name '*init*.sql' ! -name '*hive*.sql' \) | xargs cat >>/tmp/results_ohdisql.ddl && \
#     find . -maxdepth 1 -type f -name '*index*.sql'| xargs cat >>/tmp/results_ohdisql.ddl
RUN find . -type f -maxdepth 1 -not -regex '.*\(index\|init\|hive\|impala\).*' | xargs cat >/tmp/results_ohdisql.ddl && \
    find . -maxdepth 1 -type f \( -name '*init*.sql' ! -name '*hive*.sql' ! -name '*concept_hierarchy*.sql' \) | xargs cat >>/tmp/results_ohdisql.ddl && \
    find . -maxdepth 1 -type f -name '*index*.sql'| xargs cat >>/tmp/results_ohdisql.ddl

# concatenate the webapi schema flyway migration postgresql SQL files to a single postgresql SQL file - for flyway history baseline version V2.2.5.20180212152023
# When Atlas starts up connected to this Atlas postgres database it will automatically run the flyway utility
# to migrate the Atlas webapi schema tables from this baseline version to the latest version
WORKDIR /tmp/WebAPI/src/main/resources/db/migration/postgresql
RUN echo 'set search_path=webapi;' >/tmp/set_search_path_webapi.sql && \
    cat \
    /tmp/set_search_path_webapi.sql \
    V1.0.0.1__schema-create_spring_batch.sql \
    V1.0.0.2__schema-create_jpa.sql \
    V1.0.0.3__cohort_definition_persistence.sql \
    V1.0.0.3.1__cohort_generation.sql \
    V1.0.0.3.2__alter_foreign_keys.sql \
    V1.0.0.4__cohort_analysis_results.sql \
    V1.0.0.4.1__heracles_heel.sql \
    V1.0.0.4.2__measurement_types.sql \
    V1.0.0.4.3__heracles_index.sql \
    V1.0.0.5__feasability_tables.sql \
    V1.0.0.5.1__alter_foreign_keys.sql \
    V1.0.0.6.1__schema-create_laertes.sql \
    V1.0.0.6.2__schema-create_laertes.sql \
    V1.0.0.6.3__schema-create_laertes.sql \
    V1.0.0.6.4__schema-create_laertes.sql \
    V1.0.0.6.5__schema-create_penelope_laertes.sql \
    V1.0.0.7.0__sources.sql.sql \
    V1.0.0.7.1__cohort_multihomed_support.sql \
    V1.0.0.7.2__feasability_multihomed_support.sql.sql \
    V1.0.0.8__heracles_data.sql \
    V1.0.0.9__shiro_security.sql \
    V1.0.0.9.1__shiro_security-initial_values.sql \
    V1.0.1.0__conceptsets.sql \
    V1.0.1.1__penelope.sql \
    V1.0.1.1.1__penelope_data.sql \
    V1.0.1.2__conceptset_negative_controls.sql \
    V1.0.1.3__conceptset_generation_info.sql \
    V1.0.2.0__cohort_feasiblity.sql \
    V1.0.3.1__comparative_cohort_analysis.sql \
    V1.0.4.0__ir_analysis.sql \
    V1.0.4.1__ir_dist.sql \
    V1.0.5.0__rename_system_user_to_anonymous.sql \
    V1.0.6.0__schema-create-plp.sql \
    V1.0.6.0.1__schema-add-analysis_execution_password.sql \
    V1.0.7.0__alter_cohort_generation_info.sql \
    V1.0.8.0__cohort_features_results.sql \
    V1.0.9.0__data-permissions.sql \
    V1.0.10.0__data-atlas-user.sql \
    V1.0.11.0__data-cohortanalysis-permission.sql \
    V1.0.11.1__schema-executions.sql \
    V2.2.0.20180202143000__delete-unnecessary-admin-permissions.sql \
    V2.2.0.20180215143000__remove_password.sql \
    V2.2.5.20180212152023__concept-sets-author.sql \
    > /tmp/webapi_baseline_V2.2.5.20180212152023_postgresql.sql && \
    sed -i 's/\${ohdsiSchema}/webapi/g' /tmp/webapi_baseline_V2.2.5.20180212152023_postgresql.sql
WORKDIR /tmp

# get the OHDSI SqlRender tool
RUN wget http://repo.ohdsi.org:8085/nexus/repository/releases/org/ohdsi/sql/SqlRender/1.9.2/SqlRender-1.9.2.jar -O SqlRender.jar

# Use SqlRender to render and translate the WebAPI results schema tables creation SQL from ohdisql to postgresql SQL
# RUN java -jar SqlRender.jar /tmp/results_ohdisql.ddl /tmp/results_postgresql.ddl -translate postgresql -render results_schema demo_cdm_results vocab_schema demo_cdm
RUN java -jar SqlRender.jar /tmp/results_ohdisql.ddl /tmp/results_postgresql.ddl -translate postgresql -render cdm_schema cdm results_schema results vocab_schema vocab
# RUN java -jar SqlRender.jar /tmp/results_ohdisql.ddl /tmp/results_postgresql.ddl -translate postgresql -render results_schema dev_results vocab_schema webapi

#-------------------------------------------

FROM postgres:15.2-alpine as data-loader-image

WORKDIR /tmp

EXPOSE 5432

# configure postgres database defaults
ENV PGDATA=/data
ENV PGOPTIONS="--search_path=demo_cdm"

# # copy the concept recommended csv data file into the container image for Atlas Phoebe recommendations function
# COPY ./src/concept_recommended.csv.gz /tmp/concept_recommended.csv.gz

# # copy the atlas demo cdm csv data files into the container image
# RUN mkdir /tmp/atlas_demo_csv_files
# COPY ./src/demo_cdm_csv_files/*.csv.gz /tmp/demo_cdm_csv_files/

# # copy the below SQL files into the container image - postgresql database will automatically run them in this sequence when it starts up

# 010 - create empty atlas demo_cdm & atlas demo_cdm_results schemas
COPY ./src/010_create_demo_cdm_schemas.sql /docker-entrypoint-initdb.d/010_create_demo_cdm_schemas.sql

# 020 - create atlas demo_cdm schema tables
COPY ./src/020_omop_cdm_postgresql_ddl.sql /docker-entrypoint-initdb.d/020_omop_cdm_postgresql_ddl.sql

# NB: SQL 021 is split from 020 to separate the vocab schema creation from the cdm schema creation
# 021 - create atlas vocab schema tables
COPY ./src/021_omop_vocab_postgresql_ddl.sql /docker-entrypoint-initdb.d/021_omop_vocab_postgresql_ddl.sql

# # 030 - create empty achilles tables in the atlas demo_cdm_results schema
COPY ./src/030_achilles_postgresql_ddl.sql /docker-entrypoint-initdb.d/030_achilles_postgresql_ddl.sql

# # 035 - create concept_recommended table in the atlas demo_cdm schema for Atlas Phoebe recommendations functionality
# COPY ./src/035_concept_recommended.ddl.sql /docker-entrypoint-initdb.d/035_concept_recommended.ddl.sql

# # 037 - load concept recommended csv data into the atlas demo_cdm schema concept_recommended table 
# COPY ./src/037_load_concept_recommended_data.sql /docker-entrypoint-initdb.d/037_load_concept_recommended_data.sql

# # 040 - load atlas demo cdm csv data into the atlas demo_cdm schema tables & achilles data into atlas demo_cdm_results schema achilles tables
# COPY ./src/040_load_demo_cdm_data.sql /docker-entrypoint-initdb.d/040_load_demo_cdm_data.sql

# # 045 - create atlas demo_cdm schema table primary keys
# COPY ./src/045_omop_cdm_postgresql_primary_keys.sql /docker-entrypoint-initdb.d/045_omop_cdm_postgresql_primary_keys.sql

# # 050 - create atlas demo_cdm schema table indexes
# COPY ./src/050_omop_cdm_postgresql_indexes.sql /docker-entrypoint-initdb.d/050_omop_cdm_postgresql_indexes.sql

# # 060 - create atlas demo_cdm schema table database constraints - referential integrity
# #COPY ./src/060_omop_cdm_postgresql_constraints.sql /docker-entrypoint-initdb.d/060_omop_cdm_postgresql_constraints.sql

# 065 - create the atlas demo_cdm_results schema tables - the concatenated files were generated as a single postgresql SQL file using the intermediate container builder
COPY --from=builder-image /tmp/results_postgresql.ddl /docker-entrypoint-initdb.d/065_results_schema_ddl_postgresql.sql

# 070 - create an empty webapi schema
COPY ./src/070_create_webapi_schema_postgresql.sql /docker-entrypoint-initdb.d/070_create_webapi_schema_postgresql.sql

# 075 - apply the webapi schema tables flyway database migration postgresql SQL files up to baseline version V2.2.5.20180212152023
COPY --from=builder-image /tmp/webapi_baseline_V2.2.5.20180212152023_postgresql.sql /docker-entrypoint-initdb.d/075_webapi_flyway_migrations_postgresql.sql

# # 080 - create and populate webapi_security schema - Atlas ohdsi and admin users
# COPY ./src/080_create_and_populate_webapi_security_schema.sql /docker-entrypoint-initdb.d/080_create_and_populate_webapi_security_schema.sql

# # 090 - create and populate webapi roles and users - Atlas ohdsi and admin user roles
# COPY ./src/090_create_sec_roles_and_users.sql /docker-entrypoint-initdb.d/090_create_sec_roles_and_users.sql

# # 100 - populate the source and source daimon tables in the Atlas webapi schema - enables Atlas connection to this Atlas postgresql database with a demo CDM
# COPY ./src/100_populate_source_source_daimon.sql /docker-entrypoint-initdb.d/100_populate_source_source_daimon.sql
COPY ./src/100_populate_source_source_daimon.sql /docker-entrypoint-initdb.d/100_populate_source_source_daimon.sql

# # 110 - create the flyway data migration history table
# COPY ./src/110_create_flyway_schema_history_table.sql /docker-entrypoint-initdb.d/110_create_flyway_schema_history_table.sql

# # 120 - populate the flyway database migration history table with the correct entries up to baseline version V2.2.5.20180212152023
# # Atlas will automatically migrate the webapi schema tables from this baseline version to the latest version when it starts up and connects to this Atlas postgresql database with a demo CDM
# COPY ./src/120_populate_flyway_schema_history_table.sql /docker-entrypoint-initdb.d/120_populate_flyway_schema_history_table.sql

# # 130 - load demo Atlas cohort definitions
# COPY ./src/130_load_demo_atlas_cohort_definitions.sql /docker-entrypoint-initdb.d/130_load_sample_atlas_cohort_definitions.sql

# # 140 - load demo Atlas concept set definitions
# COPY ./src/140_load_demo_atlas_conceptset_definitions.sql /docker-entrypoint-initdb.d/140_load_sample_atlas_conceptset_definitions.sql

### 99X - crosspipe utility, not used in the OHDSI/WebAPI project, but is customized for the use with CrossPipe.
# # 991 - rename and create db
COPY ./src/991_crosspipe_utility.sql /docker-entrypoint-initdb.d/991_crosspipe_utility.sql

RUN ["sed", "-i", "s/exec \"$@\"/echo \"skipping...\"/", "/usr/local/bin/docker-entrypoint.sh"]

# Pseudo branching logic - we run 2 stages, 1 for default password auth, the other for secrets auth
FROM data-loader-image AS use-password-default
ENV POSTGRES_PASSWORD=mypass
ENV POSTGRES_DB=webtools
RUN ["/usr/local/bin/docker-entrypoint.sh", "postgres"]

FROM data-loader-image AS use-password-secret
ENV POSTGRES_PASSWORD_FILE="/run/secrets/ATLASDB_POSTGRES_PASSWORD"
RUN --mount=type=secret,id=ATLASDB_POSTGRES_PASSWORD \
    ["/usr/local/bin/docker-entrypoint.sh", "postgres"]

# then pick the stage based on the PASSWORD_METHOD
FROM use-password-${PASSWORD_METHOD} AS data-loader-image-final


# run the postgres entrypoint script to run the SQL scripts and load the data but do not start the postgres daemon process
FROM postgres:15.2-alpine
COPY --from=data-loader-image-final /data $PGDATA