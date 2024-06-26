#!/bin/bash -ex

tailpid=0
replicationpid=0

stopServices() {
  service apache2 stop
  service postgresql stop
  kill $replicationpid
  kill $tailpid
}
trap stopServices SIGTERM TERM INT

/app/config.sh

if id nominatim >/dev/null 2>&1; then
  echo "user nominatim already exists"
else
  useradd -m -p ${NOMINATIM_PASSWORD} nominatim
fi

#replace custom files here
cp /address.config-custom.json /usr/local/etc/nominatim/address-levels.json
cp /address_lookup.sql /usr/local/lib/nominatim/lib-sql/functions/address_lookup.sql
cp /placex_triggers.sql /usr/local/lib/nominatim/lib-sql/functions/placex_triggers.sql

IMPORT_FINISHED=/var/lib/postgresql/14/main/import-finished

if [ ! -f ${IMPORT_FINISHED} ]; then
  /app/init.sh
  touch ${IMPORT_FINISHED}
else
  chown -R nominatim:nominatim ${PROJECT_DIR}
fi

service postgresql start

cd ${PROJECT_DIR} && sudo -E -u nominatim nominatim refresh --website --functions

service apache2 start

# start continous replication process
if [ "$REPLICATION_URL" != "" ] && [ "$FREEZE" != "true" ]; then
  # run init in case replication settings changed
  sudo -E -u nominatim nominatim replication --project-dir ${PROJECT_DIR} --init
  if [ "$UPDATE_MODE" == "continuous" ]; then
    echo "starting continuous replication"
    sudo -E -u nominatim nominatim replication --project-dir ${PROJECT_DIR} &> /var/log/replication.log &
    replicationpid=${!}
  elif [ "$UPDATE_MODE" == "once" ]; then
    echo "starting replication once"
    sudo -E -u nominatim nominatim replication --project-dir ${PROJECT_DIR} --once &> /var/log/replication.log &
    replicationpid=${!}
  elif [ "$UPDATE_MODE" == "catch-up" ]; then
    echo "starting replication once in catch-up mode"
    sudo -E -u nominatim nominatim replication --project-dir ${PROJECT_DIR} --catch-up &> /var/log/replication.log &
    replicationpid=${!}
  else
    echo "skipping replication"
  fi
fi

# fork a process and wait for it
tail -Fv /var/log/postgresql/postgresql-14-main.log /var/log/apache2/access.log /var/log/apache2/error.log /var/log/replication.log &
tailpid=${!}

export NOMINATIM_QUERY_TIMEOUT=600
export NOMINATIM_REQUEST_TIMEOUT=3600
if [ "$REVERSE_ONLY" = "true" ]; then
  echo "Warm database caches for reverse queries"
  sudo -H -E -u nominatim nominatim admin --warm --reverse > /dev/null
else
  echo "Warm database caches for search and reverse queries"
  sudo -H -E -u nominatim nominatim admin --warm > /dev/null
fi
export NOMINATIM_QUERY_TIMEOUT=10
export NOMINATIM_REQUEST_TIMEOUT=60
echo "Warming finished"

echo "--> Nominatim is ready to accept requests"

wait