#!/bin/sh

set -e

. /opt/kolla/kolla-common.sh
. /opt/kolla/config-glance.sh

check_required_vars PUBLIC_IP ADMIN_TENANT_NAME \
                    GLANCE_KEYSTONE_USER GLANCE_KEYSTONE_PASSWORD \
                    GLANCE_API_SERVICE_HOST GLANCE_API_SERVICE_PORT \
# TODO Find out why check fails
# ERROR: missing check_for_keystone
#check_for_keystone

#export SERVICE_TOKEN="${KEYSTONE_ADMIN_TOKEN}"
export SERVICE_TOKEN="password"
export SERVICE_ENDPOINT="http://${KEYSTONE_ADMIN_SERVICE_HOST}:35357/v2.0"

crux user-create --update \
    -n "${GLANCE_KEYSTONE_USER}" \
    -p "${GLANCE_KEYSTONE_PASSWORD}" \
    -t "${ADMIN_TENANT_NAME}" \
    -r admin

crux endpoint-create --remove-all \
    -n glance -t image \
    -I "${GLANCE_API_SERVICE_PROTOCOL}://${GLANCE_API_SERVICE_HOST}:${GLANCE_API_SERVICE_PORT}" \
    -P "${GLANCE_API_SERVICE_PROTOCOL}://${GLANCE_API_SERVICE_HOST}:${GLANCE_API_SERVICE_PORT}" \
    -A "${GLANCE_API_SERVICE_PROTOCOL}://${GLANCE_API_SERVICE_HOST}:${GLANCE_API_SERVICE_PORT}"

exec /usr/bin/glance-api
