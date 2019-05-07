#! /bin/sh
MAIN_DIR="$(pwd)"
OPEN_DATA_ORG="open-data-toronto"

WORKSPACE_DIR="$MAIN_DIR/.."
STACK_DIR="$WORKSPACE_DIR/stack"
CKAN_DIR="$STACK_DIR/ckan"
declare -a OPEN_DATA_REPOS=("ckan-customization-open-data-toronto" "wp-open-data-toronto")

CKAN_GIT="https://github.com/ckan/ckan.git"
CKAN_TAG="ckan-2.8.0"
CKAN_DOCKER_DIR="$CKAN_DIR/contrib/docker"

CKAN_RESTART_COUNT=5
SLEEP_SECS=3

ADMIN_USERNAME=admin

declare -a STACK_CONTAINERS=("ckan" "db" "redis" "solr" "datapusher" "wordpress" "mysql")


# Set up OD workspace
echo "INFO | Setting up OD workspace"
for repo in "${OPEN_DATA_REPOS[@]}"
  do
    if [ -d "$WORKSPACE_DIR/$repo" ]; then
      echo "INFO | Pulling repo: $repo"
      cd "$WORKSPACE_DIR/$repo"
      git pull
    else
      echo "INFO | Cloning repo: $repo"
      git clone "https://github.com/$OPEN_DATA_ORG/$repo.git" "$MAIN_DIR/../$repo"
    fi
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
cp "$MAIN_DIR/docker-compose.yml" "$CKAN_DOCKER_DIR/docker-compose.yml"
cp "$MAIN_DIR/ckan-entrypoint.sh" "$CKAN_DOCKER_DIR/ckan-entrypoint.sh"
cp "$CKAN_DOCKER_DIR/.env.template" "$CKAN_DOCKER_DIR/.env"

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "INFO | Configuring files for MacOS."
    sed -i '' 's|"ckanAPI": window.location.protocol + "//" + ckan + "/api/3/action/", "ckanURL": window.location.protocol + "//" + ckan|"ckanAPI":"http://localhost:5000/api/3/action/", "ckanURL":"http://localhost:5000"|g' "$WORKSPACE_DIR/wp-open-data-toronto/wp-open-data-toronto/js/utils.js"
    echo "INFO | CKAN URL in WordPress utils.js will point to localhost:5000"
    
    sed -i '' 's,CKAN_SITE_URL=http://localhost:5000,# CKAN_SITE_URL=http://localhost:5000,g' "$CKAN_DOCKER_DIR/.env" && \
    sed -i '' 's,# CKAN_SITE_URL=http://docker.for.mac.localhost:5000,CKAN_SITE_URL=http://docker.for.mac.localhost:5000,g' "$CKAN_DOCKER_DIR/.env" && \
    echo "INFO | .env file CKAN_SITE_URL set to http://docker.for.mac.localhost:5000"
    
    sed -i '' 's|mdillon/postgis|mdillon/postgis:10|g' "$CKAN_DOCKER_DIR/postgresql/Dockerfile" && \
    echo "INFO | Postgres Dockerfile updated to pull Postgresql version 10"

elif [[ "$OSTYPE" == "linux-gnu" ]]; then
    echo "INFO: Configuring files for Linux."
    sed -i 's|"ckanAPI": window.location.protocol + "//" + ckan + "/api/3/action/", "ckanURL": window.location.protocol + "//" + ckan|"ckanAPI":"http://localhost:5000/api/3/action/", "ckanURL":"http://localhost:5000"|g' "$WORKSPACE_DIR/wp-open-data-toronto/wp-open-data-toronto/js/utils.js" && \
    echo "INFO: CKAN URL in WordPress utils.js will point to localhost:5000"

    sed -i 's|mdillon/postgis|mdillon/postgis:10|g' "$CKAN_DOCKER_DIR/postgresql/Dockerfile" && \
    echo "INFO | Postgres Dockerfile updated to pull Postgresql version 10"
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
      echo "INFO | Postgres Database not yet initialized. Restarting CKAN - try $(echo $n+1 | bc)/$CKAN_RESTART_COUNT."
      sleep $SLEEP_SECS
      docker-compose restart ckan
    else
        echo "INFO | Postgres Database initialized. Restarting one last time."
        docker-compose restart ckan
        n=$CKAN_RESTART_COUNT
    fi
  done

# ensure every container is running
for container in "${STACK_CONTAINERS[@]}"
  do
    lines=$(docker container ls --filter "name=$container" | grep $container | wc -l)
    if [[ $lines == 1 ]]; then
      echo "INFO | Container running: $container"
    else
      echo "ERROR | Container is not running: $container - $lines"
      ALL_CONTAINERS_RUNNING=false
    fi
  done

if [ "$ALL_CONTAINERS_RUNNING" = false ]; then
    echo "ERROR | Exiting. Investigate why not all containers are running"
    return
else
  echo "INFO | All of the container expected are running"
fi


sleep $SLEEP_SECS
# install DataStore
echo "INFO | Installing CKAN Datastore"
docker exec ckan /usr/local/bin/ckan-paster --plugin=ckan datastore set-permissions -c /etc/ckan/production.ini | docker exec -i db psql -U ckan

sleep $SLEEP_SECS
# install Open Data components
echo "INFO | Installing Open Data extensions"
docker exec --user 0 ckan bash /open-data-workspace/docker-local-environment/install.sh

sleep $SLEEP_SECS
# restart CKAN
echo "INFO | Restarting CKAN once more to apply extensions"
docker-compose restart ckan

echo "INFO | Quick start finished"
docker exec -it ckan /usr/local/bin/ckan-paster --plugin=ckan sysadmin -c /etc/ckan/production.ini add $ADMIN_USERNAME