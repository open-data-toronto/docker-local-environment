#! /bin/sh
cp docker-compose.yml ../../../docker/ckan/contrib/docker/docker-compose.yml  && \
cp ../../../docker/ckan/contrib/docker/.env.template ../../../docker/ckan/contrib/docker/.env

case "$OSTYPE" in
    darwin*)
    sed -i '' 's,CKAN_SITE_URL=http://localhost:5000,# CKAN_SITE_URL=http://localhost:5000,g' ../../../docker/ckan/contrib/docker/.env && \
    sed -i '' 's,# CKAN_SITE_URL=http://docker.for.mac.localhost:5000,CKAN_SITE_URL=http://docker.for.mac.localhost:5000,g' ../../../docker/ckan/contrib/docker/.env
    ;;
esac