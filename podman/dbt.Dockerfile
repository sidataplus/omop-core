## https://github.com/dbt-labs/dbt-core/blob/1.5.latest/docker/Dockerfile

##
#  Generic dockerfile for dbt image building.
#  See README for operational details
##

# Top level build args
ARG build_for=linux/amd64

##
# base image (abstract)
##
FROM --platform=$build_for python:3.11.2-slim-bullseye as base

# N.B. The refs updated automagically every release via bumpversion
# N.B. dbt-postgres is currently found in the core codebase so a value of dbt-core@<some_version> is correct

## Using `dbt-trino`
## https://pypi.org/project/dbt-trino/1.5.0/
# ARG dbt_third_party=dbt-trino@1.5.0

# System setup
RUN apt-get update \
  && apt-get dist-upgrade -y \
  && apt-get install -y --no-install-recommends \
    git \
    ssh-client \
    software-properties-common \
    make \
    build-essential \
    ca-certificates \
    libpq-dev \
  && apt-get clean \
  && rm -rf \
    /var/lib/apt/lists/* \
    /tmp/* \
    /var/tmp/*

# Env vars
ENV PYTHONIOENCODING=utf-8
ENV LANG=C.UTF-8

# Update python
RUN python -m pip install --upgrade pip setuptools wheel --no-cache-dir

# Set docker basics
WORKDIR /usr/app/dbt/
VOLUME /usr/app
ENTRYPOINT ["dbt"]



##
# dbt-third-party
##
# FROM dbt-core as dbt-third-party
FROM ghcr.io/dbt-labs/dbt-core:1.5.1 as dbt-trino
RUN python -m pip install --no-cache-dir dbt-trino==1.5.0