#!/bin/sh
#
# usage config-neutron.sh ( controller | network | compute )

[ -f /startconfig ] && . /startconfig

: ${RABBIT_HOST:=$RABBITMQ_PORT_5672_TCP_ADDR}
: ${RABBIT_USER:=guest}
: ${RABBIT_PASSWORD:=guest}
: ${ADMIN_TENANT_NAME:=admin}
: ${NEUTRON_KEYSTONE_USER:=neutron}
: ${KEYSTONE_AUTH_PROTOCOL:=http}

if ! [ "$NEUTRON_KEYSTONE_PASSWORD" ]; then
    NEUTRON_KEYSTONE_PASSWORD=$(openssl rand -hex 15)
    export NEUTRON_KEYSTONE_PASSWORD
fi

if ! [ -f /startconfig ]; then
    cat > /startconfig <<-EOF
RABBIT_HOST=${RABBIT_HOST}
RABBIT_USER=${RABBIT_USER}
RABBIT_PASSWORD=${RABBIT_PASSWORD}
ADMIN_TENANT_NAME=${ADMIN_TENANT_NAME}
KEYSTONE_AUTH_PROTOCOL=${KEYSTONE_AUTH_PROTOCOL}
NEUTRON_KEYSTONE_USER=${NEUTRON_KEYSTONE_USER}
NEUTRON_KEYSTONE_PASSWORD=${NEUTRON_KEYSTONE_PASSWORD}
EOF
fi

# Rabbit
crudini --set /etc/neutron/neutron.conf \
        DEFAULT \
        rabbit_host \
        "${RABBIT_HOST}"
crudini --set /etc/neutron/neutron.conf \
        DEFAULT \
        rabbit_userid \
        "${RABBIT_USER}"
crudini --set /etc/neutron/neutron.conf \
        DEFAULT \
        rabbit_password \
        "${RABBIT_PASSWORD}"

# Keystone
for option in auth_protocol auth_host auth_port; do
    crudini --del /etc/neutron/neutron.conf \
            keystone_authtoken \
            $option
done

crudini --set /etc/neutron/neutron.conf \
        keystone_authtoken \
        auth_uri \
        "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_PORT_5000_TCP_ADDR}:5000/"
crudini --set /etc/neutron/neutron.conf \
        keystone_authtoken \
        admin_tenant_name \
        "${ADMIN_TENANT_NAME}"
crudini --set /etc/neutron/neutron.conf \
        keystone_authtoken \
        admin_user \
        "${NEUTRON_KEYSTONE_USER}"
crudini --set /etc/neutron/neutron.conf \
        keystone_authtoken \
        admin_password \
        "${NEUTRON_KEYSTONE_PASSWORD}"

# ML2
crudini --set /etc/neutron/neutron.conf \
        DEFAULT \
        core_plugin \
        "ml2"
crudini --set /etc/neutron/neutron.conf \
        DEFAULT \
        service_plugins \
        "router"
crudini --set /etc/neutron/neutron.conf \
        DEFAULT \
        allow_overlapping_ips \
        "True"

