# How to set up a local Open Data Toronto development environment
> **Intended audience:** technical Open Data team members and collaborators who want to set up a local development environment.

This tutorial covers the steps necessary for running a local development environment that replicates the set up used by Toronto Open Data. At a high level, the components in this environment include:

1. *CKAN*: the data layer where the datasets and catalogue are stored
2. *WordPress*: the presentation layer that displays the information from CKAN. This is the page end-users visit.

## 1. Requirements
### 1.1. Folder structure
For this walkthrough we assume a directory, such as `open-data-workspace`, hosts all needed [Toronto Open Data repositories](https://github.com/open-data-toronto). This is the starting point of this walkthrough and will be referred to as the `**main directory**`.

```
open-data-workspace
│
└─── ckan-customization-open-data-toronto
│   
└─── wp-open-data-toronto
│   
└─── docker-local-environment
```

### 1.2. GitHub repositories
* [ckan-customization-open-data-toronto](https://github.com/open-data-toronto/ckan-customization-open-data-toronto): CKAN extension and plugins created for Open Data Toronto specifically
* [wp-open-data-toronto](https://github.com/open-data-toronto/wp-open-data-toronto): WordPress theme files created for Open Data Toronto specifically
* [docker-local-environment](https://github.com/open-data-toronto/docker-local-environment): scripts used by Open Data for an array of reasons, from analysis to migration

### 1.3. Docker
#### a. Docker
Docker is installed system-wide following the official Docker CE installation guidelines:
* [Linux](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
* [Mac](https://docs.docker.com/docker-for-mac/install/)
* [Windows](https://docs.docker.com/docker-for-windows/install/)

To verify a successful Docker installation, run `docker run hello-world`. `docker version` should output versions for client and server.

#### b. Docker Compose (Linux only, already included in Mac and Windows)
Docker Compose is installed system-wide following the official [Docker Compose installation guidelines](https://docs.docker.com/compose/install/). Can also be installed inside a virtual environment separate from the one inside the CKAN container and would need to be activated before running Docker Compose commands.

To verify a successful Docker Compose installation, run `docker-compose version`.

> **Note:** Docker Compose is not production-grade. This environment is for development purposes only. However, this is a starting for moving into a container orchestration platform (e.g. Kubernetes, Docker Swarm, AWS ECS).

## 2. Clone CKAN repository
In the main directory:
1. Create a new `docker` folder to house the ckan repository as weall as the local WordPress database.
2. Enter the new `docker` folder clone the CKAN code repository via `git clone https://github.com/ckan/ckan`
3. Enter the resulting `ckan` folder and check out the tag `ckan-2.8.0` via `git checkout ckan-2.8.0`.

## 3. Prepare CKAN Docker configuration files
Run the `open-data-workspace/docker-local-environment/prep.sh` script to copy Open Data files into the respective folders.

## 4. Set-up CKAN
### 4.1. Build Docker images and run containers
Navigate to `open-data-workspace/docker/ckan/contrib/docker/` and run `docker-compose up -d --build` to build and spin up the environment. Build is only needed when creating the environment for the first time or when changes are made to files in this directory.

 > **Note**: `docker-compose` files must be run from within `open-data-workspace/docker/ckan/contrib/docker/`. Other docker commands, such as `docker exec`, `docker container`, or `docker volume` can be run from elsewhere. To avoid errors it is best to execute them from the same container.

#### a. Confirm running containers and volumes
The `docker container ls` command  will return a list of running containers. There should be five:
1. *ckan*: CKAN with standard extensions
2. *db*: CKAN’s database, later also running CKAN’s datastore database
3. *redis*: A pre-built Redis image.
4. *solr*: A pre-built SolR image set up for CKAN.
5. *datapusher*: A pre-built CKAN Datapusher image.

There should also be four named Docker volumes (`docker volume ls | grep docker`) prefixed with the Docker Compose project name (default: `docker` or value of host environment variable `COMPOSE_PROJECT_NAME`.)
1. *docker_ckan_config*: home of production.ini
2. *docker_ckan_home*: home of ckan venv and source, later also additional CKAN extensions
3. *docker_ckan_storage*: home of CKAN’s filestore (resource files)
4. *docker_pg_data*: home of the database files for CKAN’s default and datastore databases

There should also be two Open Data-specific containers for WordPress:
1. *wordpress*: the Front-End of the portal, in WordPress (http://localhost:8080/)
2. *mysql*: persistent mySQL database for WordPress content

#### b. Confirm CKAN is online, restarting a few times if needed
CKAN will then be available in `http://localhost:5000`. Often when initializing the environment Postgres could take longer to spin up than CKAN; to fix restart the CKAN container a few times: `docker-compose restart ckan`.

### 4.2. Create CKAN admin user
Next, create a CKAN admin user. In this example, it is **admin**:
`docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckan sysadmin -c /etc/ckan/production.ini add admin`

Now you should be able to login to the new, empty CKAN, with full permissions.

### 4.3. Install Datastore
The datastore has already been created, just need to set permissions via the following command:
`docker exec ckan /usr/local/bin/ckan-paster --plugin=ckan datastore set-permissions -c /etc/ckan/production.ini | docker exec -i db psql -U ckan`

#### Test datatore set-up
> http://localhost:5000/api/3/action/datastore_search?resource_id=_table_metadata

### 4.4. Run Open Data installation script
Install the necessary Open Data components.
`docker exec --user 0 ckan bash /open-data-workspace/docker-local-environment/install.sh`

> **Note**: The `/usr/lib/ckan/src/ckanext-opendatatoronto` directory within the container points to the local `open-data-workspace/ckan-customization-open-data-toronto` folder. Changes can be made locally then tested after restarting the container.

### 4.5. Restart the CKAN container to apply changes to production.ini 
Restart the CKAN container to apply changes `docker-compose restart ckan`

### 4.6. Bringing down the environment
To bring down the environment use `docker-compose down`

## 5. Set-up Wordpress
Navigate to `http://localhost:8080` to set-up the WordPress instance. Then, from the administrator dashboard at `http://localhost:8080/wp-admin`:
1. Go to `Appearance --> Themes` (http://localhost:8080/wp-admin/themes.php)
2. Locate the `WP Open Data Toronto` theme
3. Click on `Activate`.

> **Note**: Theme directory is a mounted volume pointing to the `open-data-workspace/wp-open-data-toronto/` local directory. Changes in the local directory are thus reflected in WordPress immediately upon browser refresh.

### 5.2. Update permalink format
Go to `Settings --> Permalinks`, select `Post name` under Common Settings, and save the changes.

### 5.3. Create placeholder WordPress pages
Go to `Pages` and create the following pages:

* Page: Data Catalogue
    * Permalink: http://localhost:8080/catalogue/ 
    * Template: Catalogue Page
* Page: Homepage
    * Permalink: http://localhost:8080/homepage/
    * Template: Homepage
* Page: Dataset
    * Permalink: http://localhost:8080/dataset/
    * Template: Dataset Page
    
These are needed for triggering the JS needed to populate the homepage, data catalogue, and dataset pages from CKAN.

### 5.4. Set homepage
Next, need to set the homepage so that http://localhost:8080/ 

Go to `Settings --> Reading` and, under `Your homepage displays`:
1. Select `A static page (select below)`
2. Select `Homepage` in the `Homepage` dropdown

## 6. Troubleshooting Common Issues
To view logs, run command: `docker-compose logs -f ckan`.

### 6.1. CKAN is not showing any datasets but I know they are there
Need to reindex the catalogue **each time** the environment is spun up. From outside the docker container:
`docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckan search-index rebuild -c /etc/ckan/production.ini`

### 6.2. CKAN is not initializing
Often when initializing the environment Postgres could take longer to spin up than CKAN; to fix restart the CKAN container a few times: `docker-compose restart ckan`.