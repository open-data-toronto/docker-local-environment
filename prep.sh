#! /bin/sh
sed -i '' 's|"ckanAPI": window.location.protocol + "//" + ckan + "/api/3/action/", "ckanURL": window.location.protocol + "//" + ckan|"ckanAPI":"http://localhost:5000/api/3/action/", "ckanURL":"http://localhost:5000"|g' ../wp-open-data-toronto/wp-open-data-toronto/js/utils.js

cp docker-compose.yml ../docker/ckan/contrib/docker/docker-compose.yml  && \
cp ../docker/ckan/contrib/docker/.env.template ../docker/ckan/contrib/docker/.env

case "$OSTYPE" in
    darwin*)
    sed -i '' 's,CKAN_SITE_URL=http://localhost:5000,# CKAN_SITE_URL=http://localhost:5000,g' ../docker/ckan/contrib/docker/.env && \
    sed -i '' 's,# CKAN_SITE_URL=http://docker.for.mac.localhost:5000,CKAN_SITE_URL=http://docker.for.mac.localhost:5000,g' ../docker/ckan/contrib/docker/.env
    ;;
esac