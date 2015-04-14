#!/bin/bash

set -e

. /opt/kolla/kolla-common.sh
. /opt/kolla/config-cinder.sh

: ${ISCSI_HELPER:="tgtadm"}
: ${VOLUME_GROUP:="cinder-volumes"}
: ${VOLUME_NAME_TEMPLATE:="volumes-%s"}
: ${VOLUME_DRIVER=" cinder.volume.drivers.lvm.LVMISCSIDriver"}

check_required_vars VOLUME_API_LISTEN ISCSI_IP_ADDRESS \
                    MARIADB_SERVICE_HOST DB_ROOT_PASSWORD \
                    CINDER_DB_NAME CINDER_DB_USER CINDER_DB_PASSWORD

fail_unless_db

mysql -h ${MARIADB_SERVICE_HOST} -u root \
        -p${DB_ROOT_PASSWORD} mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${CINDER_DB_NAME};
GRANT ALL PRIVILEGES ON ${CINDER_DB_NAME}.* TO
        '${CINDER_DB_USER}'@'%' IDENTIFIED BY '${CINDER_DB_PASSWORD}'
EOF

#-----Cinder.conf setup-----

# osapi
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        osapi_volume_listen \
        ${VOLUME_API_LISTEN}

# iscsi
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        iscsi_ip_address \
        ${ISCSI_IP_ADDRESS}
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        iscsi_helper \
        ${ISCSI_HELPER}

# volume_group
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        volume_group \
        ${VOLUME_GROUP}
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        volume_driver \
        ${VOLUME_DRIVER}


wait_for 30 1 check_for_os_service_running keystone

export SERVICE_TOKEN="${KEYSTONE_ADMIN_TOKEN}"
export SERVICE_ENDPOINT="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}/v2.0"

crux user-create --update \
    -n "${CINDER_KEYSTONE_USER}" \
    -p "${CINDER_KEYSTONE_PASSWORD}" \
    -t "${ADMIN_TENANT_NAME}" \
    -r admin

crux endpoint-create --remove-all \
    -n cinder -t volume \
    -P "http://${PUBLIC_IP}:8776/v1/\$(tenant_id)s" \
    -A "http://${CINDER_API_SERVICE_HOST}:8776/v1/\$(tenant_id)s" \
    -I "http://${CINDER_API_SERVICE_HOST}:8776/v1/\$(tenant_id)s"


echo "Starting cinder-volume"
cinder-manage db sync
exec /usr/bin/cinder-volume
