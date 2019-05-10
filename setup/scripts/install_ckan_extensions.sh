#! /bin/sh

# This script installs the extensions used by Toronto Open Data in CKAN and copies the
# production.ini file from the config folder afterwards to apply them upon  restart

. /usr/lib/ckan/venv/bin/activate && \
cd /usr/lib/ckan/venv/src && \
pip install -e "git+https://github.com/ckan/ckanext-spatial.git#egg=ckanext-spatial" && \
pip install -r ckanext-spatial/pip-requirements.txt && \
pip install ckanext-geoview && \
pip install -e ckanext-opendatatoronto && \
pip install -r ckanext-opendatatoronto/requirements.txt && \
cp /open-data-workspace/docker-local-environment/setup/files/production.ini /etc/ckan/production.ini
