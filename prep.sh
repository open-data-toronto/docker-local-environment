#! /bin/sh
echo "STARTED: Preparing Open Data configuration files"
cp docker-compose.yml ../docker/ckan/contrib/docker/docker-compose.yml  && \
cp ../docker/ckan/contrib/docker/.env.template ../docker/ckan/contrib/docker/.env

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "FOUND: Running on Macos. Configuring files for MacOS."
    sed -i '' 's|"ckanAPI": window.location.protocol + "//" + ckan + "/api/3/action/", "ckanURL": window.location.protocol + "//" + ckan|"ckanAPI":"http://localhost:5000/api/3/action/", "ckanURL":"http://localhost:5000"|g' ../wp-open-data-toronto/wp-open-data-toronto/js/utils.js && \
    echo "UPDATED: CKAN URL in WordPress utils.js will point to localhost:5000"
    
    sed -i '' 's,CKAN_SITE_URL=http://localhost:5000,# CKAN_SITE_URL=http://localhost:5000,g' ../docker/ckan/contrib/docker/.env && \
    sed -i '' 's,# CKAN_SITE_URL=http://docker.for.mac.localhost:5000,CKAN_SITE_URL=http://docker.for.mac.localhost:5000,g' ../docker/ckan/contrib/docker/.env
    echo "UPDATED: .env file CKAN_SITE_URL set to http://docker.for.mac.localhost:5000"

elif [[ "$OSTYPE" == "linux-gnu" ]]; then
    echo "FOUND: Running on Linux. Configuring files for Linux."
    sed -i 's|"ckanAPI": window.location.protocol + "//" + ckan + "/api/3/action/", "ckanURL": window.location.protocol + "//" + ckan|"ckanAPI":"http://localhost:5000/api/3/action/", "ckanURL":"http://localhost:5000"|g' ../wp-open-data-toronto/wp-open-data-toronto/js/utils.js
    echo "UPDATED: CKAN URL in WordPress utils.js will point to localhost:5000"

fi

echo "FINISHED: Preparation complete. Please proceed to the next step."
