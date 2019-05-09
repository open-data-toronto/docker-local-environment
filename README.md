# Set up a local Open Data Toronto development environment in Docker

> **Intended audience:** technical Open Data team members, municipalities, collaborators, and friends who want to contribute to Open Data.

This tutorial covers the steps necessary for running a local environment that replicates the set-up used by Toronto Open Data. At a high level, the components in this environment include:

1. *[CKAN](https://ckan.org/)*: the leading open source open data platform we are using to store our catalogue and power our APIs for consuming data. Effectively the data layer.
2. *[WordPress](https://wordpress.com/)*: the site end-users actually see, in essence communicates with CKAN and creates pages dynamically. This is the presentation layer.

## 1. Requirements

### 1.1. Operating system

For the time being, Quick Start only works for Linux and MacOS. Expansion to Windows in the future planned.

### 1.2. Folder structure

For this walkthrough we assume a directory will host all the [Toronto Open Data repositories](https://github.com/open-data-toronto) needed. In this tutorial we call it `open-data-workspace`  and refer to it as the *workspace directory*. Essentially:

```

open-data-workspace
│
└─── docker-local-environment (this repository)

```

> **IMPORTANT!**: Relevant Toronto Open Data git repositories will be cloned into folders created in the *workspace directory* throughout this process. Repos that already exist in the workspace directory will be reset and any changes will be lost - 

### 1.3. Docker

#### Docker

Docker is installed system-wide following the official Docker CE installation guidelines ([Linux](https://docs.docker.com/install/linux/docker-ce/ubuntu/), [Mac](https://docs.docker.com/docker-for-mac/install/), [Windows](https://docs.docker.com/docker-for-windows/install/)).

To verify a successful Docker installation, run `docker run hello-world`. `docker version` should output versions for client and server.

#### Docker Compose (Linux only, already included in Docker for Mac/Windows)

Docker Compose is installed system-wide following the official [Docker Compose installation guidelines](https://docs.docker.com/compose/install/). Can also be installed inside a virtual environment separate from the one inside the CKAN container and would need to be activated before running Docker Compose commands.

To verify a successful Docker Compose installation, run `docker-compose version`.

> **IMPORTANT:** Docker Compose is **not production-grade**. This environment is for development purposes only. However, this is a starting for moving into a container orchestration platform (e.g. Kubernetes, Docker Swarm).

## 2. Set-up CKAN

To install CKAN and the extensions we use in Open Data, we recommend running the "quick start" script we created to simplify this process and minimize errors.

Go to `open-data-workspace/docker-local-environment/scripts` and run via:

    . quick_start_ckan.sh

CKAN will then be available at: http://localhost:5000/

> **IMPORTANT!** The script must be run from within the directory. For detailed steps on what this script does, see the [scripts folder](https://github.com/open-data-toronto/docker-local-environment/tree/master/scripts).

### Creating a user administrator

At the end of the installation script, you will be prompted to create an administration user (by default, the username is `admin`). If the prompt timesout, you opt to skip it for now, or want to create another user in the future, run the command below (in this example, the user is called `admin` but you can change that):

    docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckan sysadmin -c /etc/ckan/production.ini add admin

A few important notes around creating users:

1. Command will only work when the CKAN container is running
2. Users can be created through the UI but they can only be made administrators via the command above
3. When running that command, the user will be created if it does not exist

### Developing on CKAN

The Toronto Open Data extension files are mounted from the local directory at `open-data-workspace/ckan-customization-open-data-toronto`. Changes in the local directory will be reflected after restarting the container; to do so, go to the location of the `docker-compose.yml` file (`open-data-workspace/stack/ckan/contrib/docker`) and run:

    docker-compose restart ckan

## 3. Set-up Wordpress

From your browser, visit `http://localhost:8080` and fill out the form to set-up a WordPress site.

### 3.1. Activate the WP Open Data Toronto Theme

From the administrator dashboard at `http://localhost:8080/wp-admin` follow the steps below:

1. Go to `Appearance --> Themes` (http://localhost:8080/wp-admin/themes.php)
2. Locate the `WP Open Data Toronto` theme
3. Click on `Activate`.

> **Note**: Theme is mounted from the local directory `open-data-workspace/wp-open-data-toronto/`. Changes in the local directory are thus reflected in WordPress immediately upon browser refresh.

### 3.2. Update permalink format

Go to `Settings --> Permalinks`, select `Post name` under Common Settings, and save the changes.

### 3.3. Create placeholder WordPress pages

Go to `Pages` and create the following pages:

* Page: Catalogue
  * Permalink: http://localhost:8080/catalogue/
  * Template: Catalogue Page
* Page: Homepage
  * Permalink: http://localhost:8080/homepage/
  * Template: Homepage
* Page: Dataset
  * Permalink: http://localhost:8080/dataset/
  * Template: Dataset Page

These are needed for triggering the JS needed to populate the homepage, data catalogue, and dataset pages from CKAN.

### 3.4. Set homepage

Next, need to set the homepage so that http://localhost:8080/

Go to `Settings --> Reading` and, under `Your homepage displays`:

1. Select `A static page (select below)`
2. Select `Homepage` in the `Homepage` dropdown

### 4. Bring the environment up/down

To bring the environment "up" (online) or "down" (i.e. shut down) will need to go to `open-data-workspace/stack/ckan/contrib/docker` and execute the commands below.

1. Bringing it online: `docker-compose up`
2. Shutting it down: `docker-compose down`

> **Note**: Will work for both CKAN *AND* WordPress, because they are under the same Docker Compose file. This could be decoupled in the future.

## 5. Troubleshooting

> *Note*: all docker-compose commands must be run from the location of the docker-compose.yml file, which by default is at `open-data-workspace/stack/ckan/contrib/docker`

To view logs:

    docker-compose logs

To print the logs live, pass `-f` as an argument like so:

    docker-compose logs -f

To view the logs for a single service, end with the name of the container. For example:

    docker-compose logs ckan

Will print out the logs from the CKAN service only, if we substitute that with "db" (name of the Postgres container) will print out only those logs and so on. We can bring all that together and use, for example:

    docker-compose logs -f solr

To follow the logs for solr only.

### CKAN is not showing any datasets but I know they are there

Sometimes the solr index goes out of sync with CKAN, and it needs to be rebuilt. If this is the case, don't worry! Your data is still there.

To rebuild the index, run the command below from outside the container:

    docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckan search-index rebuild -c /etc/ckan/production.ini

### CKAN keeps crashing when initializing

Often when initializing Postgres could take longer to spin up than CKAN; to fix restart the CKAN container a few times via:

    docker-compose restart ckan

## 6. Contribution

All contributions, bug reports, bug fixes, documentation improvements, enhancements and ideas are welcome.

### Reporting issues

Please report issues [here](https://github.com/open-data-toronto/docker-local-environment/issues).

### Contributing

Please develop in your own branch and create Pull Requests into the `dev` branch when ready for review and merge.

### HELP WANTED

Quick start only works for Linux and MacOS. We would like some help to port it over to Windows as well.

Contact carlos.hernandez@toronto.ca if interested

## 7. License

* [MIT License](https://github.com/open-data-toronto/docker-local-environment/blob/master/LICENSE)
