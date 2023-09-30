# omop-core
Part of OMOP NHSO TCELS project

## About Repo

This repository is organized into separate directories, each representing a different component, a brief description of its content:

- [container/](container/): Scripts for building and composing containers, Every infrastructure component is containerized and can be run independently.

- [dwh/](dwh/): Specific configuration and setup files for the Data Warehouse, which is responsible for managing the database server.

- [pipelines/](pipelines/): SQL scripts for data transformation. For the source to OMOP CDM transformation, it is recommended to have a separate repository dedicated to this task, rather than including it in this repository.

- [utils/](utils/): This directory is for miscellaneous files that may not be actively used in the project but are referenced from the project's Wiki or other documents.

- [webtools/](webtools/): Working directory path for R Server and ATLAS.

### Obsoleted
Merged to [container/podman/](container/podman/)
- [podman/](podman/): Scripts for building and composing containers using Podman.