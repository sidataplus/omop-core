# omop-core
Part of OMOP NHSO TCELS project

## About Repo

This repository is organized into separate directories, each representing a different component, a brief description of its content:

- [dwh/](dwh/): Specific configuration and setup files for the Data Warehouse, which is responsible for managing the database server.

- [pipelines/](pipelines/): SQL scripts for data transformation. For the source to OMOP CDM transformation, it is recommended to have a separate repository dedicated to this task, rather than including it in this repository.

- [podman/](podman/): Scripts for building and composing containers using Podman.

- [utils/](utils/): This directory is for miscellaneous files that may not be actively used in the project but are referenced from the project's Wiki or other documents.