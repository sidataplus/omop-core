# # /opt/spark/bin/spark-submit --driver-memory 4g backup.py

###
# NB: Apache Spark architecture did not support to print out the progress of the job.,
#     Try not to waste time on this.
###


import time
import threading
from pyspark.sql import SparkSession
import os
import sys


# Initialize a Spark session
spark = SparkSession.builder \
    .appName("PostgreSQLDataTransfer") \
    .getOrCreate()

# spark = SparkSession.builder.appName("ETL").config('spark.ui.showConsoleProgress', 'true').getOrCreate()
spark.sparkContext.setLogLevel("WARN")

# Get the source and target instance from command line
# In this use case, parameters are provided from CrossPipe CLI
# If not provided, use OMOP and ATLAS as default
source_instance=sys.argv[1]
target_instance=sys.argv[2]

# Define the JDBC connection properties for source and target databases
source_properties = {
    "url": os.environ[f'JDBC_{source_instance}_URL'],
    "user": os.environ[f'JDBC_{source_instance}_USERNAME'],
    "password": os.environ[f'JDBC_{source_instance}_PASSWORD'],
    "schema_cdm": os.environ[f'JDBC_{source_instance}_SCHEMA_CDM'],
    "schema_vocab": os.environ[f'JDBC_{source_instance}_SCHEMA_VOCAB'],
    "driver": "org.postgresql.Driver"
}

target_properties = {
    "url": os.environ[f'JDBC_{target_instance}_URL'],
    "user": os.environ[f'JDBC_{target_instance}_USERNAME'],
    "password": os.environ[f'JDBC_{target_instance}_PASSWORD'],
    "schema_cdm": os.environ[f'JDBC_{target_instance}_SCHEMA_CDM'],
    "schema_vocab": os.environ[f'JDBC_{target_instance}_SCHEMA_VOCAB'],
    "driver": "org.postgresql.Driver"
}

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

# Read data from the source PostgreSQL table for each table in the source schema and write to target table
print(f"Fetching from production {source_instance}:")
source_schemas = ["webapi", "results"]
target_schemas = ["webapi", "results"]

print(f"Working with {len(source_schemas)} schemas:")
for i, schema in enumerate(source_schemas):
    try:
        print(f"[{i+1}/{len(source_schemas)}] Reading tables from source schema '{schema}'...")
        source_tables = spark.read.jdbc(url=source_properties["url"], table="information_schema.tables", properties=source_properties)
        source_tables = source_tables.filter((source_tables.table_type == "BASE TABLE") & (source_tables.table_schema == schema)).select("table_name").collect()
        source_tables = sorted([row["table_name"] for row in source_tables])
        
        print(f"[{i+1}/{len(source_schemas)}] Writing tables to target schema '{target_schemas[i]}'...")
        for j, tbl in enumerate(source_tables):
            try:
                print(f"[{i+1}/{len(source_schemas)}][{j+1}/{len(source_tables)}] Reading data from source database for table '{tbl}'...")
                start_time = time.time()
                source_df = spark.read \
                    .jdbc(url=source_properties["url"],
                          table=f"{schema}.{tbl}",
                          properties=source_properties)

                print(f"[{i+1}/{len(source_schemas)}][{j+1}/{len(source_tables)}] Writing data to target database for table '{tbl}'...")
                target_df = source_df.write \
                    .jdbc(url=target_properties["url"],
                          table=f"{target_schemas[i]}.{tbl}",
                          mode="overwrite",  # You can change this to append or ignore if needed
                          properties=target_properties)
                end_time = time.time()
                row_count = source_df.count()
                print(f"[{i+1}/{len(source_schemas)}][{j+1}/{len(source_tables)}] Data transfer for table '{tbl}' is complete. Time spent: {end_time - start_time:.2f} seconds. Total rows loaded: {row_count}\n")
            except:
                print(f"[{i+1}/{len(source_schemas)}][{j+1}/{len(source_tables)}] Table '{tbl}' does not exist in the source database. Skipping to next table.\n")
    except:
        print(f"[{i+1}/{len(source_schemas)}] Schema '{schema}' does not exist in the source database. Skipping to next schema.\n")

# Stop the Spark session
spark.stop()
