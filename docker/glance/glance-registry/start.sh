#!/bin/sh

set -e

. /opt/kolla/kolla-common.sh
. /opt/kolla/config-glance.sh

check_required_vars GLANCE_DB_NAME GLANCE_DB_USER GLANCE_DB_PASSWORD
check_for_db

mysql -h ${MARIADB_SERVICE_HOST} -u root -p${DB_ROOT_PASSWORD} mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${GLANCE_DB_NAME} DEFAULT CHARACTER SET utf8;
GRANT ALL PRIVILEGES ON ${GLANCE_DB_NAME}.* TO
       '${GLANCE_DB_USER}'@'%' IDENTIFIED BY '${GLANCE_DB_PASSWORD}'

EOF

# Initialize the Glance DB
echo "Initializing Glance DB"
if [ "${INIT_DB}" == "true" ] || [ "${INIT_DB}" == "True" ] ; then
  /usr/bin/glance-manage db_sync
fi

exec /usr/bin/glance-registry
