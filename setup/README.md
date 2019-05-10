# Setup

These scripts were created to facilitate the installation and configuration of the local environment and minimize manual steps where necessary. Details on what they do below.

> **Note**: must be run from within this folder

## quick_start.sh

This script initializes the environment by creating the core stack (i.e. CKAN, WordPress) and installing the extensions used by Open Data.

### Actions performed

1. Clones CKAN Extensions and WordPress Theme repos if they do not exist locally; otherwise resets them
2. Checks out the latest production tags for each repo above (v2.1.1)
3. Creates a `stack` directory for storing environment files and CKAN source code
4. Clones (or resets) the CKAN source core repo that has the Docker image and compose files we build on
5. Replaces default files with ones specific to the environment (e.g. configuration, settings, etc)
6. Builds and initializes all parts of the environment via `docker-compose.yml`

### Docker containers that compose the environment

The `docker container ls` command  will return a list of running containers. There should be 7:

1. *ckan*: CKAN with standard extensions
2. *db*: CKAN’s database, later also running CKAN’s datastore database
3. *redis*: A pre-built Redis image.
4. *solr*: A pre-built SolR image set up for CKAN.
5. *datapusher*: A pre-built CKAN Datapusher image.
6. *wordpress*: the Front-End of the portal, in WordPress ([http://localhost:8080/](http://localhost:8080/))
7. *mysql*: persistent mySQL database for WordPress content

### Docker volumes used for persistent storage

There should also be four named Docker volumes (`docker volume ls | grep docker`) prefixed with the Docker Compose project name (default: `docker` or value of host environment variable `COMPOSE_PROJECT_NAME`.)

1. *docker_ckan_config*: home of production.ini
2. *docker_ckan_home*: files used by CKAN
3. *docker_ckan_storage*: filestore (i.e. where dataset resources are stored)
4. *docker_pg_data*: data for CKAN’s Postgres database
5. *docker_solr*: persistent solr data

### GitHub repositories cloned (if they do not exist) or reset (if they do)

* [ckan-customization-open-data-toronto](https://github.com/open-data-toronto/ckan-customization-open-data-toronto): CKAN extension and plugins created for Open Data Toronto specifically.
* [wp-open-data-toronto](https://github.com/open-data-toronto/wp-open-data-toronto): WordPress theme files created for Open Data Toronto specifically.
* [ckan](https://github.com/ckan/ckan): for the CKAN code and Dockerfiles/docker compose files of images used for the environment.

> **IMPORTANT!** if these repositories already exist they will be reset and all changes will be lost. Make sure to store any desired changes somewhere else before running the quick start and copy them over when done.

## load_examples.sh

After environment is initialized, this script loads it with example data to give an idea of the functionality of the portal.

  . load_examples.sh **<API_KEY>**

> **Note**: Requires an *API_KEY*. To get it go to CKAN ([http://localhost:5000](http://localhost:5000)), log in with the account created at the end of the `quick_start.sh` script above, click on the username in the top right, and copy from the sidebar on the left.
