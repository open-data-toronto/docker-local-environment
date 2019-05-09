#! /bin/sh

cd ~/

virtualenv setup

{
  source ./setup/bin/activate

  pip install -U pip
  pip install ckanapi geopandas

  cd /open-data-workspace/docker-local-environment/ckan_init/

  python ckan_init.py $1
  
} || {
  echo 'Unable to initialize Python environment'
}

rm -rf setup
