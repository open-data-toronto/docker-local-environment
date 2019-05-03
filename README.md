# How to set up a local Open Data Toronto development environment
> **Intended audience:** technical Open Data team members and collaborators who want to set up a local development environment.

This tutorial covers the steps necessary for running a local development environment that replicates the set up used by Toronto Open Data. At a high level, the components in this environment include:

1. CKAN: the data layer where the datasets and catalogue are stored
2. WordPress: the presentation layer that displays the information from CKAN. This is the page end-users visit.
3. Development instances: used for consistent development within Open Data. So far these include an Ubuntu instance running Jupyter Lab, ann an Alpine instance running NodeJS.

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

> **Note:** Docker Compose is not production-grade. This environment is for development purposes only. However, this is a starting point for replicating CKAN and WordPress elements in container orchestration platforms (e.g. Kubernetes, Docker Swarm, AWS ECS) for production deployment

## 2. Clone CKAN repository
In the main directory:
1. Create a new `docker` folder to house the ckan repository as weall as the local WordPress database.
2. Enter the new `docker` folder clone the CKAN code repository via `git clone https://github.com/ckan/ckan`
3. Enter the resulting `ckan` folder and check out the tag `ckan-2.8.0` via `git checkout ckan-2.8.0`.

## 3. Prepare CKAN Docker configuration files
Run the `open-data-workspace/docker-local-environment/prep.sh` script to copy Open Data configuration files into the CKAN directory.

## 4. Run CKAN
> The following steps for spinning up CKAN in docker are taken from the official CKAN documentation at https://docs.ckan.org/en/2.8/maintaining/installing/install-from-docker-compose.html

### 4.1. Build Docker images and run containers
In this step we will build the Docker images and create Docker data volumes with user-defined, sensitive settings (e.g. database passwords). 

Navigate to `open-data-workspace/docker/ckan/contrib/docker/` and run `docker-compose up -d --build` to build and bring up the environment in detached mode.

> **Note**: After the first build, `--build` is only needed if changes are made to files in this directory; otherwise, `docker-compose up -d` will bring up the environment in detached mode.

When initializing Postgres could take longer to spin up than CKAN. To fix, restart the CKAN container: `docker-compose restart ckan`.

#### a. Confirm running Docker containers and volumes
The `docker container ls` command  will return a list of running containers. There should be five CKAN-related containers running:

1. ckan: CKAN with standard extensions
2. db: CKAN’s database, later also running CKAN’s datastore database
3. redis: A pre-built Redis image.
4. solr: A pre-built SolR image set up for CKAN.
5. datapusher: A pre-built CKAN Datapusher image.

There should be four named Docker volumes (`docker volume ls | grep docker`). They will be prefixed with the Docker Compose project name (default: `docker` or value of host environment variable `COMPOSE_PROJECT_NAME`.)

1. docker_ckan_config: home of production.ini
2. docker_ckan_home: home of ckan venv and source, later also additional CKAN extensions
3. docker_ckan_storage: home of CKAN’s filestore (resource files)
4. docker_pg_data: home of the database files for CKAN’s default and datastore databases

Additionally, there should be two Open Data-specific containers:
1. wordpress: the Front-End of the portal, in WordPress (http://localhost:8080/)
2. mysql: persistent mySQL database for WordPress content

#### b. Confirm CKAN is online 
CKAN will then be available in `http://localhost:5000`.

#### c. Troubleshoot initialization issues.
Often when initializing the environment Postgres could take longer to spin up than CKAN; to fix restart the CKAN container: `docker-compose restart ckan`.

To view logs, run command: `docker-compose logs -f ckan`.

### 4.2. Create CKAN admin user
With all images up and running, create the CKAN admin user (`admin` in this example):

`docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckan sysadmin -c /etc/ckan/production.ini add carlos`

Now you should be able to login to the new, empty CKAN. The admin user’s API key will be instrumental in tranferring data from other instances.

### 4.3. Install Open Data components
#### a. Datastore and datapusher
The datastore has already been created, permissions just need to be set in order to activate it. From the terminal, outside the CKAN container, run the following command:

`docker exec ckan /usr/local/bin/ckan-paster --plugin=ckan datastore set-permissions -c /etc/ckan/production.ini | docker exec -i db psql -U ckan`

##### To test the set-up
> http://localhost:5000/api/3/action/datastore_search?resource_id=_table_metadata

#### b. Run Open Data installation script
Install the necessary Open Data components:
`docker exec --user 0 ckan bash /open-data-workspace/docker-local-environment/install.sh`

> **Note**: The CKAN Toronto Open Data extension in the `/usr/lib/ckan/src/ckanext-opendatatoronto` folder within the container is pointing to the local folder `open-data-workspace/ckan-customization-open-data-toronto` folder. Changes can be made here and tested in CKAN after restarting the sertive with the command below

#### c. Restart the CKAN container to apply changes to production.ini 
Restart to apply changes:
`docker-compose restart ckan`

### 4.4. Bringing down the environment
To bring down the environment:
`docker-compose down`

### 4.5. IMPORTANT - Troubleshooting: no datasets showing in UI
Need to reindex the catalogue **each time** the environment is spun up.
`docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckan search-index rebuild -c /etc/ckan/production.ini`

## 5. RUN WordPress
### 5.1. Initialize WordPress and install theme
Navigate to `http://localhost:8080` to access the WordPress instance and follow the instructions to install WordPress.

After logging in you will be in the administrator dashboard, which can also be accessed via `http://localhost:8080/wp-admin`.

Go to `Appearance --> Themes` (http://localhost:8080/wp-admin/themes.php), locate the `WP Open Data Toronto` theme and click on `Activate`.

> **Note**: This theme is actually a mounted volume which points to the host machine from `open-data-workspace/wp-open-data-toronto/` folder. This means that any changes to local files are reflected in WordPress immediately upon browser refresh.

### 5.2. Update permalink format
Go to `Settings --> Permalinks`, select `Post name` under Common Settings, and save the changes.

### 5.3. Create placeholder WordPress pages
Go to `Pages` and create the following:

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

### 5.5. Modify utils.js file
From the main folder, navigate to `wp-open-data-toronto/wp-open-data-toronto/js` and locate the `utils.js` file. This file determines the CKAN URL to use for the API calls based on the WordPress URL.

Since this is for local purposes only, we need to set have WordPress call the local CKAN. Replace `var config` with:

```
var config = {
    'ckanAPI': 'http://' + "localhost:5000" + '/api/3/action/',
    'ckanURL': 'http://' + "localhost:5000" 
}
```

> **Note**: Alternatively, this could also be set to the Toronto Open Data Portal URL instead.
