#!/bin/sh

set -e

. /opt/kolla/kolla-common.sh

: ${ADMIN_TENANT_NAME:=admin}
: ${CINDER_DB_NAME:=cinder}
: ${CINDER_DB_USER:=cinder}
: ${CINDER_KEYSTONE_USER:=cinder}
: ${KEYSTONE_AUTH_PROTOCOL:=http}
: ${PUBLIC_IP:=$CINDER_API_PORT_8004_TCP_ADDR}
: ${RABBIT_USERID:=guest}
: ${RABBIT_PASSWORD:=guest}

check_required_vars CINDER_DB_PASSWORD CINDER_KEYSTONE_PASSWORD \
                    KEYSTONE_PUBLIC_SERVICE_HOST RABBITMQ_SERVICE_HOST \
                    GLANCE_API_SERVICE_HOST MARIADB_SERVICE_HOST

dump_vars

cat > /openrc <<EOF
export OS_AUTH_URL="http://${KEYSTONE_PUBLIC_SERVICE_HOST}:${KEYSTONE_PUBLIC_SERVICE_PORT}/v2.0"
export OS_USERNAME="${CINDER_KEYSTONE_USER}"
export OS_PASSWORD="${CINDER_KEYSTONE_PASSWORD}"
export OS_TENANT_NAME="${ADMIN_TENANT_NAME}"
EOF

cfg=/etc/cinder/cinder.conf

# logs
crudini --set $cfg \
        DEFAULT \
        log_dir
crudini --set $cfg \
        DEFAULT \
        log_file \
        ""

# verbose
crudini --set $cfg \
        DEFAULT \
        verbose \
        "True"

# debug
crudini --set $cfg \
        DEFAULT \
        debug \
        "False"

# backend
crudini --set $cfg \
        DEFAULT \
        rpc_backend \
        "cinder.openstack.common.rpc.impl_kombu"

# rabbit
crudini --set $cfg \
        DEFAULT \
        rabbit_host \
        ${RABBITMQ_SERVICE_HOST}
crudini --set $cfg \
        DEFAULT \
        rabbit_port \
        5672
crudini --set $cfg \
        DEFAULT \
        rabbit_hosts \
        ${RABBITMQ_SERVICE_HOST}:5672
crudini --set $cfg \
        DEFAULT \
        rabbit_userid \
        ${RABBIT_USERID}
crudini --set $cfg \
        DEFAULT \
        rabbit_password \
        "${RABBIT_PASSWORD}"
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        rabbit_virtual_host \
        "/"
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        rabbit_ha_queues \
        "False"

# glance
crudini --set $cfg \
        DEFAULT \
        glance_host \
        ${GLANCE_API_SERVICE_HOST}

# database
crudini --set $cfg \
        database \
        connection \
        mysql://${CINDER_DB_USER}:${CINDER_DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${CINDER_DB_NAME}

# keystone
crudini --set $cfg \
        DEFAULT \
        auth_strategy \
        "keystone"
crudini --set $cfg \
        keystone_authtoken \
        auth_protocol \
        ${KEYSTONE_AUTH_PROTOCOL}
crudini --set $cfg \
        keystone_authtoken \
        auth_host \
        ${KEYSTONE_PUBLIC_SERVICE_HOST}
crudini --set $cfg \
        keystone_authtoken \
        auth_port \
        ${KEYSTONE_PUBLIC_SERVICE_PORT}
crudini --set $cfg \
        keystone_authtoken \
        auth_uri \
        ${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}:${KEYSTONE_PUBLIC_SERVICE_PORT}/v2.0
crudini --set $cfg \
        keystone_authtoken \
        admin_tenant_name \
        ${ADMIN_TENANT_NAME}
crudini --set $cfg \
        keystone_authtoken \
        admin_user \
        ${CINDER_KEYSTONE_USER}
crudini --set $cfg \
        keystone_authtoken \
        admin_password \
        "${CINDER_KEYSTONE_PASSWORD}"
