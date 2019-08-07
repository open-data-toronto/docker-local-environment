# Overview of files

* **ckan-entrypoint.sh**: Added command to rebuild the solr index each time it is spun up.
* **config.js**: Contains the local CKAN URL WordPress will call to show on the front-end (in the production repo this is determined dynamically).
* **docker-compose.yml**: Added volume for persistent solr storage (taken from CKAN repo).
* **production.ini**: CKAN configuration settings.
