#!/bin/bash

set -e

. /opt/kolla/kolla-common.sh
. /opt/kolla/config-cinder.sh

: ${CINDER_DB_USER:=cinder}
: ${CINDER_DB_NAME:=cinder}
: ${KEYSTONE_AUTH_PROTOCOL:=http}
: ${CINDER_KEYSTONE_USER:=cinder}
: ${ADMIN_TENANT_NAME:=admin}

if ! [ "$CINDER_DB_PASSWORD" ]; then
        CINDER_DB_PASSWORD=$(openssl rand -hex 15)
        export CINDER_DB_PASSWORD
fi

check_required_vars KEYSTONE_ADMIN_TOKEN KEYSTONE_ADMIN_SERVICE_HOST \
                    CINDER_ADMIN_PASSWORD PUBLIC_IP CINDER_API_SERVICE_HOST \
                    ISCSI_IP

#-----Cinder.conf setup-----

# Cinder database
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        db_driver \
        "cinder.db"

# control_exchange
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        control_exchange \
        "openstack"

# osapi
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        osapi_volume_listen \
        "0.0.0.0"

# iscsi
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        iscsi_ip_address \
        ${ISCSI_IP}
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        iscsi_helper \
        "tgtadm"

# volume_group
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        volume_group \
        "cinder-volumes"

echo "Starting cinder-api"
exec /usr/bin/cinder-api
