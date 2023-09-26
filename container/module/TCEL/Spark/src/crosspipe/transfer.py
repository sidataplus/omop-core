# # /opt/spark/bin/spark-submit --driver-memory 4g transfer.py

###
# NB: Apache Spark architecture did not support to print out the progress of the job.,
#     Try not to waste time on this.
###


import time
import threading
from pyspark.sql import SparkSession

# Initialize a Spark session
spark = SparkSession.builder \
    .appName("PostgreSQLDataTransfer") \
    .config('spark.ui.showConsoleProgress', 'true') \
    .getOrCreate()

# spark = SparkSession.builder.appName("ETL").config('spark.ui.showConsoleProgress', 'true').getOrCreate()
spark.sparkContext.setLogLevel("WARN")

# Define the JDBC connection properties for source and target databases
source_properties = {
    "url": "jdbc:postgresql://omop-pg:5432/omop_yourorg",
    "user": "omopuser",
    "password": "P@ssw0rd",
    "driver": "org.postgresql.Driver"
}

target_properties = {
    "url": "jdbc:postgresql://ohdsi-webapi-pg:5432/webtools",
    "user": "postgres",
    "password": "mypass",
    "driver": "org.postgresql.Driver"
}

def heartbeat_check():
    while True:
        # Perform your heartbeat check here
        print("Heartbeat check...")
        time.sleep(30)  # Sleep for 30 seconds

# Start the heartbeat check thread
heartbeat_thread = threading.Thread(target=heartbeat_check)
heartbeat_thread.daemon = True  # Allow the thread to exit when the main program exits
heartbeat_thread.start()

# Read data from the source PostgreSQL table
print("JDBC: Source")
source_df = spark.read \
    .jdbc(url=source_properties["url"],
          table="vocab.concept_relationship",
          properties=source_properties)

print("JDBC: Target")
# Write data to the target PostgreSQL table
target_df = source_df.write \
    .jdbc(url=target_properties["url"],
          table="webapi.concept_relationship",
          mode="overwrite",  # You can change this to append or ignore if needed
          properties=target_properties)

print("JDBC: Done")

# # Stop the Spark session
spark.stop()
