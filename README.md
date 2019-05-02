# How to set up a local Open Data Toronto development environment
> **Intended audience:** technical Open Data team members and collaborators who want to set up a local development environment.

This tutorial covers the steps necessary for running a local development environment that replicates the set up used by Toronto Open Data. At a high level, the components in this environment include:

1. CKAN: the data layer where the datasets and catalogue are stored
2. WordPress: the presentation layer that displays the information from CKAN. This is the page end-users visit.
3. Development instances: used for consistent development within Open Data. So far these include an Ubuntu instance running Jupyter Lab, ann an Alpine instance running NodeJS.

## 1. Requirements
### 1.1. Project directory structure
For this walkthrough we assume a directory, such as `open-data-workspace`, hosts all Toronto Open Data Repositories as outlined below. This is the starting point of this walkthrough and will be referred to as the "main directory".

```
open-data-workspace
│
└─── ckan-customization-open-data-toronto
│   
└─── wp-open-data-toronto
│   
└─── open-data-private
```

### 1.2. GitHub repositories
* [ckan-customization-open-data-toronto](https://github.com/CityofToronto/ckan-customization-open-data-toronto): CKAN extension and plugins created for Open Data Toronto specifically
* [wp-open-data-toronto](https://github.com/CityofToronto/wp-open-data-toronto): WordPress theme files created for Open Data Toronto specifically
* [open-data-private](https://github.com/CityofToronto/open-data-private): scripts used by Open Data for an array of reasons, from analysis to migration

### 1.3. Docker
#### a. Docker
Docker is installed system-wide following the official Docker CE installation guidelines:
* [Linux](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
* [Mac](https://docs.docker.com/docker-for-mac/install/)
* [Windows](https://docs.docker.com/docker-for-windows/install/)

To verify a successful Docker installation, run `docker run hello-world`. `docker version` should output versions for client and server.

#### b. Docker Compose (Linux only)
> **Note:** Docker Compose is included in `Docker for Mac` and `Docker for Windows`, this step applies to Linux only.

Docker Compose is installed system-wide following the official [Docker Compose installation guidelines](https://docs.docker.com/compose/install/). Alternatively, Docker Compose can be installed inside a virtualenv, which would be entirely separate from the virtualenv used inside the CKAN container, and would need to be activated before running Docker Compose commands.

To verify a successful Docker Compose installation, run docker-compose version.

> **Note:** since Docker Compose is not meant for production, this environment is only for development, collaboration, and debugging. However, this is a starting point for replicating CKAN and WordPress elements in production-ready container orchestration platforms (e.g. Kubernetes, Docker Swarm, AWS ECS) for robust deployment

## 2. Set up local directory for Docker files
In the main directory create a new `docker` folder to house the ckan repository as weall as the local WordPress database.

Go into the `docker` folder and clone the CKAN code repository via `git clone https://github.com/ckan/ckan`, then into the resulting `ckan` folder and check out the tag `ckan-2.8.0` via `git checkout ckan-2.8.0`.

## 3. Replace CKAN docker-compose.yml with Open Data docker-compose.yml
Go to `open-data-workspace/docker/ckan/contrib/docker` **from this point forward, it is assumed all commands are run from this directory, where the `docker-compose.yml` is located.**

The CKAN repository already has the files needed for creating and running a local CKAN environment in Docker via a `docker-compose.yml` file. We just need to add the WordPress instances:
1. WordPress
2. MySQL (for WordPress)

Replace `docker-compose.yml` with `../../../../open-data-private/environments/ckan/docker-compose.yml`.

## 4. CKAN
> The following steps for spinning up CKAN in docker are taken from the official CKAN documentation in https://docs.ckan.org/en/2.8/maintaining/installing/install-from-docker-compose.html

### 4.1. Build Docker images
In this step we will build the Docker images and create Docker data volumes with user-defined, sensitive settings (e.g. database passwords).

#### a. Sensitive settings and environment variables
Copy `.env.template` to `.env`. Open the file and follow instructions within to set passwords and other sensitive or user-defined variables.

> **Note**: the `.env.template` file is hidden so, if you cannot see it, try this step via a terminal or command prompt.

The defaults will work fine in a development environment on Linux. For OSX, the CKAN_SITE_URL must be updated.

#### b. Build the images
In the terminal run `docker-compose up -d --build` to build up the files and bring up the environment.

> **Note**: After the first build, `--build` is only needed if changes are made to files in this directory; otherwise, `docker-compose up -d` is enough to bring up the environment in detached mode.

On first runs, the postgres container could need longer to initialize the database cluster than the ckan container will wait for. This time span depends heavily on available system resources. If the CKAN logs show problems connecting to the database, restart the ckan container a few times.

To view the logs: `docker-compose logs -f ckan`.

To restart the ckan container: `docker-compose restart ckan`.

Afterwards, CKAN should be available at the `CKAN_SITE_URL` variable specified in `.env` file.

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

The location of these named volumes needs to be backed up in a production environment. To migrate CKAN data between different hosts, simply transfer the content of the named volumes - refer to the official documentation for details.

There should also be two containers related to Open Data, for WordPress:

1. wordpress: the Front-End of the portal, in WordPress (http://localhost:8080/)
2. mysql: persistent mySQL database for WordPress content

#### c. Convenience: paths to named volumes (optional)
The files inside named volumes reside on a long-ish path on the host. Purely for convenience, one can define environment variables for these paths. Refer to the documentation if this is of interest.

### 4.2. Create CKAN admin user
With all images up and running, create the CKAN admin user (`admin` in this example):

`docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckan sysadmin -c /etc/ckan/production.ini add admin`

Now you should be able to login to the new, empty CKAN. The admin user’s API key will be instrumental in tranferring data from other instances.

### 4.4. Install Open Data components
#### a. Datastore and datapusher
The datastore has already been created, permissions just need to be set in order to activate it. From the terminal, outside the CKAN container, run the following command:

`docker exec ckan /usr/local/bin/ckan-paster --plugin=ckan datastore set-permissions -c /etc/ckan/production.ini | docker exec -i db psql -U ckan`

Now the datastore API should return content when visiting:

> CKAN_SITE_URL/api/3/action/datastore_search?resource_id=_table_metadata

#### b. Run Open Data installation script
Install the necessary Open Data components:
`docker exec --user 0 ckan bash /open-data-workspace/open-data-private/environments/ckan/install.sh`

> **Note**: The CKAN Toronto Open Data extension in the `/usr/lib/ckan/src/ckanext-opendatatoronto` folder within the container is pointing to the local folder `open-data-workspace/ckan-customization-open-data-toronto` folder. Changes can be made here and tested in CKAN after restarting the sertive with the command below

#### c. Restart the CKAN container to apply changes to production.ini 
Restart to apply changes:
`docker-compose restart ckan`

### 4.5. Bringing down the environment
To bring down the environment:
`docker-compose down`

### 4.6. IMPORTANT - Troubleshooting: no datasets showing in UI
Need to reindex the catalogue **each time** the environment is spun up.
`docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckan search-index rebuild -c /etc/ckan/production.ini`

## 5. Setup WordPress
### 5.1. Initialize WordPress and install theme
Navigate to `http://localhost:8080` to access the WordPress instance and follow the instructions to install WordPress.

After logging in you will be in the administrator dashboard, which can also be accessed via `http://localhost:8080/wp-admin`.

Go to `Appearance --> Themes` (http://localhost:8080/wp-admin/themes.php), locate the `WP Open Data Toronto` theme and click on `Activate`.

> **Note**: This theme is actually a mounted volume which points to the host machine's `open-data-workspace/wp-open-data-toronto/` folder. This means that any changes to local files are reflected in WordPress immediately upon browser refresh.

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
