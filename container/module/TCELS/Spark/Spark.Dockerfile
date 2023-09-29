FROM ghcr.io/apache/spark-docker/spark:3.5.0-python3

USER root

## Python dependency: typer
RUN pip install "typer[all]"; \
    rm -rf /var/lib/apt/lists/*

## Download JDBC driver for Apache Spark: Postgresql
RUN cd /opt/spark/jars; \
    wget -nv -O postgresql-42.6.0.jar "https://jdbc.postgresql.org/download/postgresql-42.6.0.jar";

RUN export SPARK_CLASSPATH=/opt/spark/jars/postgresql-42.6.0.jar

USER spark