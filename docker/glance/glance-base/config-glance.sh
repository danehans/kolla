#!/bin/sh

set -e

. /opt/kolla/kolla-common.sh

# DB Params
: ${INIT_DB:=true}
: ${MARIADB_SERVICE_HOST:=$PUBLIC_IP}
: ${DB_ROOT_PASSWORD:=password}
: ${GLANCE_DB_NAME:=glance}
: ${GLANCE_DB_USER:=glance}
: ${GLANCE_DB_PASSWORD:=password}
# IP/Port Binding Params
: ${API_BIND_HOST:=0.0.0.0}
: ${REGISTRY_BIND_HOST:=0.0.0.0}
: ${API_BIND_PORT:=9292}
: ${REGISTRY_BIND_PORT:=9191}
# Keystone Params
: ${ADMIN_TENANT_NAME:=admin}
: ${GLANCE_KEYSTONE_USER:=glance}
: ${GLANCE_KEYSTONE_PASSWORD:=password}
: ${GLANCE_API_SERVICE_PROTOCOL:=http}
: ${GLANCE_API_SERVICE_HOST:=$PUBLIC_IP}
: ${GLANCE_API_SERVICE_PORT:=$API_BIND_PORT}
: ${KEYSTONE_AUTH_PROTOCOL:=http}
: ${KEYSTONE_PUBLIC_SERVICE_HOST:=$PUBLIC_IP}
: ${KEYSTONE_PUBLIC_SERVICE_PORT:=5000}
: ${KEYSTONE_ADMIN_SERVICE_HOST:=$PUBLIC_IP}
: ${KEYSTONE_ADMIN_SERVICE_PORT:=35357}
: ${KEYSTONE_API_VERSION:=2.0}
: ${PASTE_DEPLOY_FLAVOR:=keystone}
# Image Store Parms
: ${DEFAULT_STORE:=file}
: ${FILESYSTEM_STORE_DATADIR:=/var/lib/glance/images/}
# Swift Params
: ${SWIFT_STORE_TENANT:=jdoe}
: ${SWIFT_STORE_USER:=jdoe}
# Notification Params
: ${NOTIFICATION_DRIVER:=noop}
# Logging Params
: ${VERBOSE_LOGGING:=true}
: ${DEBUG_LOGGING:=false}

check_for_db
check_required_vars GLANCE_DB_PASSWORD GLANCE_KEYSTONE_PASSWORD \
                    KEYSTONE_PUBLIC_SERVICE_HOST KEYSTONE_AUTH_PROTOCOL \
                    KEYSTONE_ADMIN_SERVICE_HOST KEYSTONE_ADMIN_SERVICE_PORT \
                    KEYSTONE_API_VERSION GLANCE_KEYSTONE_USER ADMIN_TENANT_NAME
dump_vars

cat > /admin-openrc <<EOF
export OS_AUTH_URL="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}/v${KEYSTONE_API_VERSION}"
export OS_USERNAME="${GLANCE_KEYSTONE_USER}"
export OS_PASSWORD="${GLANCE_KEYSTONE_PASSWORD}"
export OS_TENANT_NAME="${ADMIN_TENANT_NAME}"
EOF

for cfg in /etc/glance/glance-api.conf /etc/glance/glance-registry.conf; do
    # Logging Configuration
    crudini --set $cfg \
        DEFAULT \
        log_file \
	""
    crudini --set $cfg \
        DEFAULT \
        verbose \
        ${VERBOSE_LOGGING}
    crudini --set $cfg \
        DEFAULT \
        debug \
        ${DEBUG_LOGGING}

    # Notification driver
    crudini --set $cfg \
        DEFAULT \
        notification_driver \
        ${NOTIFICATION_DRIVER}

    # Remove legacy Keystone config parameters
    for option in auth_protocol auth_host auth_port; do
        crudini --del $cfg \
            keystone_authtoken \
            $option
    done

    # Configure Keystone auth
    crudini --set $cfg \
        keystone_authtoken \
        auth_uri \
        "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}:${KEYSTONE_PUBLIC_SERVICE_PORT}/v${KEYSTONE_API_VERSION}"
    crudini --set $cfg \
        keystone_authtoken \
        identity_uri \
        "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_SERVICE_HOST}:${KEYSTONE_ADMIN_SERVICE_PORT}"
    crudini --set $cfg \
        keystone_authtoken \
        admin_tenant_name \
        "${ADMIN_TENANT_NAME}"
    crudini --set $cfg \
        keystone_authtoken \
        admin_user \
        "${GLANCE_KEYSTONE_USER}"
    crudini --set $cfg \
        keystone_authtoken \
        admin_password \
        "${GLANCE_KEYSTONE_PASSWORD}"

    # Configure deployment flavor
    crudini --set $cfg \
        DEFAULT \
        workers \
        "$(/usr/bin/nproc)"

    # Configure DB
    crudini --set $cfg \
        database \
        connection \
        "mysql://${GLANCE_DB_USER}:${GLANCE_DB_PASSWORD}@${MARIADB_SERVICE_HOST}/${GLANCE_DB_NAME}"

    # Configure deployment flavor
    crudini --set $cfg \
        paste_deploy \
        flavor \
        "${PASTE_DEPLOY_FLAVOR}"
done

api_cfg=/etc/glance/glance-api.conf

crudini --set $api_cfg \
    DEFAULT \
    bind_port \
    "${API_BIND_PORT}"

# Address to bind API service to
crudini --set $api_cfg \
    DEFAULT \
    bind_host \
    ${API_BIND_HOST}

# Address of Registry host
crudini --set $api_cfg \
    DEFAULT \
    registry_host \
    ${REGISTRY_BIND_HOST}

# Port used by Registry service
crudini --set $api_cfg \
    DEFAULT \
    registry_port \
    ${REGISTRY_BIND_PORT}

crudini --set $api_cfg \
    glance_store \
    default_store \
    "${DEFAULT_STORE}"

crudini --set $api_cfg \
    glance_store \
    filesystem_store_datadir \
    "${FILESYSTEM_STORE_DATADIR}"

crudini --set $api_cfg \
    glance_store \
    swift_store_auth_address \
    ${KEYSTONE_PUBLIC_SERVICE_HOST}:${KEYSTONE_PUBLIC_SERVICE_PORT}/v${KEYSTONE_API_VERSION}/

crudini --set $api_cfg \
    glance_store \
    swift_store_user \
    ${SWIFT_STORE_TENANT}:${SWIFT_STORE_USER}

reg_cfg=/etc/glance/glance-registry.conf

# Address to bind Registry service to
crudini --set $reg_cfg \
    DEFAULT \
    bind_host \
    ${REGISTRY_BIND_HOST}

# Port Registry services binds to
crudini --set $reg_cfg \
    DEFAULT \
    bind_port \
    ${REGISTRY_BIND_PORT}

