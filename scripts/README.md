# Installation via quick_start_ckan.sh

These scripts were created to facilitate the installation and configuration of the local environment and minimize manual steps where necessary. More on what these scripts do is below.

## Actions performed

1. Clones CKAN Extensions and WordPress Theme repos if they do not exist locally; otherwise resets them
2. Checks out the latest production tags for each repo above (v2.1.1)
3. Creates a `stack` directory for storing environment files and CKAN source code
4. Clones (or resets) the CKAN source core repo that has the Docker image and compose files we build on
5. Replaces default files with ones specific to the environment (e.g. configuration, settings, etc)
6. Builds and initializes all parts of the environment via `docker-compose.yml`

## Docker containers that compose the environment 

The `docker container ls` command  will return a list of running containers. There should be 7:

1. *ckan*: CKAN with standard extensions
2. *db*: CKAN’s database, later also running CKAN’s datastore database
3. *redis*: A pre-built Redis image.
4. *solr*: A pre-built SolR image set up for CKAN.
5. *datapusher*: A pre-built CKAN Datapusher image.
6. *wordpress*: the Front-End of the portal, in WordPress (http://localhost:8080/)
7. *mysql*: persistent mySQL database for WordPress content

## Docker volumes used for persistent storage

There should also be four named Docker volumes (`docker volume ls | grep docker`) prefixed with the Docker Compose project name (default: `docker` or value of host environment variable `COMPOSE_PROJECT_NAME`.)

1. *docker_ckan_config*: home of production.ini
2. *docker_ckan_home*: files used by CKAN
3. *docker_ckan_storage*: filestore (i.e. where dataset resources are stored)
4. *docker_pg_data*: data for CKAN’s Postgres database
5. *docker_solr*: persistent solr data
