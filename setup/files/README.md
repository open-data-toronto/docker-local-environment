# Overview of files

* **ckan-entrypoint.sh**: Added command to rebuild the solr index each time it is spun up.
* **docker-compose.yml**: Added volume for persistent solr storage. Taken from CKAN repo, will not need this file once we upgrade our version of CKAN.
* **homepage.php**: removed featured post sections due to plugin issues. Plan to replace in the future.
* **production.ini**: CKAN configuration settings.