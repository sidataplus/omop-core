# # /opt/spark/bin/spark-submit --driver-memory 4g transfer.py

###
# NB: Apache Spark architecture did not support to print out the progress of the job.,
#     Try not to waste time on this.
###


import time
import threading
from pyspark.sql import SparkSession
import os


# Initialize a Spark session
spark = SparkSession.builder \
    .appName("PostgreSQLDataTransfer") \
    .getOrCreate()

# spark = SparkSession.builder.appName("ETL").config('spark.ui.showConsoleProgress', 'true').getOrCreate()
spark.sparkContext.setLogLevel("WARN")

# Define the JDBC connection properties for source and target databases
source_properties = {
    "url": os.environ['JDBC_OMOP_URL'],
    "user": os.environ['JDBC_OMOP_USERNAME'],
    "password": os.environ['JDBC_OMOP_PASSWORD'],
    "schema_cdm": os.environ['JDBC_OMOP_SCHEMA_CDM'],
    "schema_vocab": os.environ['JDBC_OMOP_SCHEMA_VOCAB'],
    "driver": "org.postgresql.Driver"
}

target_properties = {
    "url": os.environ['JDBC_ATLAS_URL'],
    "user": os.environ['JDBC_ATLAS_USERNAME'],
    "password": os.environ['JDBC_ATLAS_PASSWORD'],
    "schema_cdm": os.environ['JDBC_ATLAS_SCHEMA_CDM'],
    "schema_vocab": os.environ['JDBC_ATLAS_SCHEMA_VOCAB'],
    "driver": "org.postgresql.Driver"
}

tbls_cdm = [
    "condition_era",
    "condition_occurrence",
    "death",
    "device_exposure",
    "dose_era",
    "drug_era",
    "drug_exposure",
    "measurement",
    "note",
    "observation",
    "observation_period",
    "payer_plan_period",
    "person",
    "procedure_occurrence",
    "specimen",
    "visit_occurrence"
]

tbls_vocab = [
    "concept",
    "concept_ancestor",
    "concept_class",
    "concept_relationship",
    "concept_synonym",
    "domain",
    "drug_strength",
    "relationship",
    "source_to_concept_map",
    "vocabulary"
]


# # List From ddl
#
# tbls_cdm = [
#     "PERSON",
#     "OBSERVATION_PERIOD",
#     "VISIT_OCCURRENCE",
#     "VISIT_DETAIL",
#     "CONDITION_OCCURRENCE",
#     "DRUG_EXPOSURE",
#     "PROCEDURE_OCCURRENCE",
#     "DEVICE_EXPOSURE",
#     "MEASUREMENT",
#     "OBSERVATION",
#     "DEATH",
#     "NOTE",
#     "NOTE_NLP",
#     "SPECIMEN",
#     "FACT_RELATIONSHIP",
#     "LOCATION",
#     "CARE_SITE",
#     "PROVIDER",
#     "PAYER_PLAN_PERIOD",
#     "COST",
#     "DRUG_ERA",
#     "DOSE_ERA",
#     "CONDITION_ERA",
#     "EPISODE",
#     "EPISODE_EVENT",
#     "METADATA",
#     # "CDM_SOURCE"
# ]



def heartbeat_check():
    # Print total heartbeat wait time
    heartbeat_time = 0
    while True:
        try:
            # Perform your heartbeat check here
            time.sleep(30)  # Sleep for 30 seconds
            heartbeat_time += 30
            print("Heartbeat.. " + str(heartbeat_time) + " seconds elapsed")
        except:
            # If an exception is raised, log the error and continue the loop
            print("DEAD! Error occurred during heartbeat check")
            continue

# Start the heartbeat check thread
heartbeat_thread = threading.Thread(target=heartbeat_check)
heartbeat_thread.daemon = True  # Allow the thread to exit when the main program exits
heartbeat_thread.start()

# Read data from the source PostgreSQL table for each table in tbls_cdm list and write to target table
print("Working on cdm transfer:")
for i, tbl in enumerate(tbls_cdm):
    try:
        print(f"[{i+1}/{len(tbls_cdm)}] Reading data from source database for table '{tbl}'...")
        start_time = time.time()
        source_df = spark.read \
            .jdbc(url=source_properties["url"],
                  table=f"{source_properties['schema_cdm']}.{tbl}",
                  properties=source_properties)
        
        print(f"[{i+1}/{len(tbls_cdm)}] Writing data to target database for table '{tbl}'...")
        target_df = source_df.write \
            .jdbc(url=target_properties["url"],
                  table=f"{target_properties['schema_cdm']}.{tbl}",
                  mode="overwrite",  # You can change this to append or ignore if needed
                  properties=target_properties)
        end_time = time.time()
        row_count = source_df.count()
        print(f"[{i+1}/{len(tbls_cdm)}] Data transfer for table '{tbl}' is complete. Time spent: {end_time - start_time:.2f} seconds. Total rows loaded: {row_count}\n")
    except:
        print(f"[{i+1}/{len(tbls_cdm)}] Table '{tbl}' does not exist in the source database. Skipping to next table.\n")

# Read data from the source PostgreSQL table for each table in tbls_vocab list and write to target table
print("Working on vocab transfer:")
for i, tbl in enumerate(tbls_vocab):
    try:
        print(f"[{i+1}/{len(tbls_vocab)}] Reading data from source database for table '{tbl}'...")
        start_time = time.time()
        source_df = spark.read \
            .jdbc(url=source_properties["url"],
                  table=f"{source_properties['schema_vocab']}.{tbl}",
                  properties=source_properties)
        
        print(f"[{i+1}/{len(tbls_vocab)}] Writing data to target database for table '{tbl}'...")
        target_df = source_df.write \
            .jdbc(url=target_properties["url"],
                  table=f"{target_properties['schema_vocab']}.{tbl}",
                  mode="overwrite",  # You can change this to append or ignore if needed
                  properties=target_properties)
        end_time = time.time()
        row_count = source_df.count()
        print(f"[{i+1}/{len(tbls_vocab)}] Data transfer for table '{tbl}' is complete. Time spent: {end_time - start_time:.2f} seconds. Total rows loaded: {row_count}\n")
    except:
        print(f"[{i+1}/{len(tbls_vocab)}] Table '{tbl}' does not exist in the source database. Skipping to next table.\n")

# # Stop the Spark session
spark.stop()
