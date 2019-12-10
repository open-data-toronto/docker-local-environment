#! /bin/sh
SETUP_DIR="$(pwd)"
OPEN_DATA_ORG="open-data-toronto"

MAIN_DIR="$SETUP_DIR/.."
WORKSPACE_DIR="$MAIN_DIR/.."
FILES_DIR="$SETUP_DIR/files"
SCRIPTS_DIR="$SETUP_DIR/scripts"
STACK_DIR="$WORKSPACE_DIR/stack"
CKAN_DIR="$STACK_DIR/ckan"
CKAN_DOCKER_DIR="$CKAN_DIR/contrib/docker"
WP_THEME_DIR="$WORKSPACE_DIR/wp-open-data-toronto/wp-open-data-toronto"

CKAN_GIT="https://github.com/ckan/ckan.git"
CKAN_TAG="ckan-2.8.2"

CKAN_RESTART_COUNT=5
SLEEP_SECS=60

declare -a OPEN_DATA_REPOS=("ckan-customization-open-data-toronto:v2.2.0" "wp-open-data-toronto:v2.2.1")
declare -a STACK_CONTAINERS=("ckan" "db" "redis" "solr" "datapusher" "wordpress" "mysql")

# Set up OD workspace
echo "INFO | Setting up OD workspace"
for repo_string in "${OPEN_DATA_REPOS[@]}"
  do
      arrIN=(${repo_string//:/ })
      repo=${arrIN[0]}
      tag=${arrIN[1]}
      if [[ "$tag" == "" ]]; then
        tag="master"
      fi

    if [ -d "$WORKSPACE_DIR/$repo" ]; then
      echo "INFO | Pulling repo: $repo"
      cd "$WORKSPACE_DIR/$repo"
      git reset --hard
      git checkout master
      git pull
    else
      echo "INFO | Cloning repo: $repo"
      git clone "https://github.com/$OPEN_DATA_ORG/$repo.git" "$MAIN_DIR/../$repo"
    fi

    cd "$WORKSPACE_DIR/$repo"
    git checkout $tag

  done

# Create Open Data Stack folder
if ! [ -d "$STACK_DIR" ]; then
  echo "INFO | Creating stack folder: $STACK_DIR"
  mkdir $STACK_DIR
fi

# Get CKAN code repository (with Docker files)
if [ -d "$CKAN_DIR" ]; then
  echo "INFO | Pulling repo: $CKAN_DIR"
  cd $CKAN_DIR
  git reset --hard
  git checkout master
  git pull
else
  echo "INFO | Cloning repo: $repo"
  cd $STACK_DIR
  git clone $CKAN_GIT
fi
cd $CKAN_DIR
git checkout $CKAN_TAG

# Prepare Open Data configuration files
echo "INFO | Preparing Open Data configuration files"
cp "$FILES_DIR/docker-compose.yml" "$CKAN_DOCKER_DIR/docker-compose.yml"
cp "$FILES_DIR/ckan-entrypoint.sh" "$CKAN_DOCKER_DIR/ckan-entrypoint.sh"
cp "$FILES_DIR/config.js" "$WP_THEME_DIR/js/config.js"
cp "$CKAN_DOCKER_DIR/.env.template" "$CKAN_DOCKER_DIR/.env"

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "INFO | Configuring files for MacOS."
    sed -i '' 's,CKAN_SITE_URL=http://localhost:5000,# CKAN_SITE_URL=http://localhost:5000,g' "$CKAN_DOCKER_DIR/.env" && \
    sed -i '' 's,# CKAN_SITE_URL=http://docker.for.mac.localhost:5000,CKAN_SITE_URL=http://docker.for.mac.localhost:5000,g' "$CKAN_DOCKER_DIR/.env" && \
    echo "INFO | .env file CKAN_SITE_URL set to http://docker.for.mac.localhost:5000"

    sed -i '' 's|mdillon/postgis|mdillon/postgis:9.6|g' "$CKAN_DOCKER_DIR/postgresql/Dockerfile" && \
    echo "INFO | Postgres Dockerfile updated to pull Postgresql version 9.6"

elif [[ "$OSTYPE" == "linux-gnu" ]]; then
    echo "INFO | Configuring files for Linux."
    sed -i 's|mdillon/postgis|mdillon/postgis:9.6|g' "$CKAN_DOCKER_DIR/postgresql/Dockerfile" && \
    echo "INFO | Postgres Dockerfile updated to pull Postgresql version 9.6"
fi

# initializing Open Data environment
cd $CKAN_DOCKER_DIR
docker-compose up -d --build

# ensuring DB container starts before CKAN container
echo "INFO | Checking that Postgres started before CKAN"
for ((n=0;n<$CKAN_RESTART_COUNT;n++))
  do
    success_db=$(docker-compose logs ckan | grep "Initialising DB: SUCCESS")
    if [[ $success_db == "" ]]; then
      echo "INFO | Postgres Database not yet initialized. Restarting CKAN while waiting for it (try $(echo $n+1 | bc)/$CKAN_RESTART_COUNT)."
      sleep $SLEEP_SECS
      docker-compose restart ckan
    else
        echo "INFO | Postgres Database initialized successfully. Restarting one last time just in case."
        docker-compose restart ckan
        n=$CKAN_RESTART_COUNT
    fi
  done

# ensure every container is running
ALL_CONTAINERS_RUNNING=true
for container in "${STACK_CONTAINERS[@]}"
  do
    lines=$(docker container ls --filter "name=$container" | grep $container | wc -l)
    if [[ "$OSTYPE" == "darwin"* ]]; then
      if [ $lines == 0 ]; then
        echo "ERROR | Container is not running: $container"
        ALL_CONTAINERS_RUNNING=false
      fi
    elif [[ "$OSTYPE" == "linux-gnu" ]]; then
      if [[ $lines == 0 ]]; then
        echo "ERROR | Container is not running: $container"
        ALL_CONTAINERS_RUNNING=false
      fi
    fi
  done

if [ $ALL_CONTAINERS_RUNNING == false ]; then
    echo "ERROR | Exiting. Investigate why not all containers are running"
    return
else
  echo "INFO | All expected containers are running"
fi


sleep $SLEEP_SECS

# install DataStore
echo "INFO | Installing CKAN Datastore"
docker exec ckan /usr/local/bin/ckan-paster --plugin=ckan datastore set-permissions -c /etc/ckan/production.ini | docker exec -i db psql -U ckan

# install Open Data components
echo "INFO | Installing Open Data extensions"
docker exec --user 0 ckan bash /open-data-workspace/docker-local-environment/setup/scripts/install_ckan_extensions.sh

# restart CKAN
echo "INFO | Restarting CKAN once more to apply extensions"
docker-compose restart ckan

sleep $SLEEP_SECS

echo
echo
echo "================================================================================"
echo
echo "INFO | CKAN Installed and configured"
echo
echo "================================================================================"
echo
echo

echo "INFO | Create administrator"
read -p "Enter username: " ADMIN_USERNAME
read -p "Create user $ADMIN_USERNAME? [y/n] " yn
case $yn in
    [Yy]* ) docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckan sysadmin -c /etc/ckan/production.ini add $ADMIN_USERNAME;; #; break;;
    [Nn]* ) echo "INFO | Admin user will need to be created. Skipping.";;
    * ) echo "WARNING | Invalid answer. Skipping.";;
esac

echo
echo
echo "================================================================================"
echo
echo "CKAN should be online and ready for development at http://localhost:5000/"
echo
echo "WordPress must be configured manually. Please refer to the documentation."
echo
echo "================================================================================"
echo
echo

cd $MAIN_DIR
