#!/bin/bash

: ${NEUTRON_DB_NAME:=neutron}
: ${NEUTRON_DB_USER:=neutron}
: ${NEUTRON_KEYSTONE_USER:=neutron}
: ${ADMIN_TENANT_NAME:=admin}
: ${NOVA_ADMIN_PASSWORD:=kolla}

if ! [ "$NEUTRON_DB_PASSWORD" ]; then
    NEUTRON_DB_PASSWORD=$(openssl rand -hex 15)
    export NEUTRON_DB_PASSWORD
fi

if ! [ "$KEYSTONE_ADMIN_TOKEN" ]; then
        echo "*** Missing KEYSTONE_ADMIN_TOKEN" >&2
        exit 1
fi

if ! [ "$DB_ROOT_PASSWORD" ]; then
        echo "*** Missing DB_ROOT_PASSWORD" >&2
        exit 1
fi

. /opt/neutron/config-neutron.sh

mysql -h ${MARIADB_PORT_3306_TCP_ADDR} -u root -p${DB_ROOT_PASSWORD} mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${NEUTRON_DB_NAME} DEFAULT CHARACTER SET utf8;
GRANT ALL PRIVILEGES ON ${NEUTRON_DB_NAME}.* TO
       '${NEUTRON_DB_USER}'@'%' IDENTIFIED BY '${NEUTRON_DB_PASSWORD}'

EOF

export SERVICE_TOKEN="${KEYSTONE_ADMIN_TOKEN}"
export SERVICE_ENDPOINT="${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_ADMIN_PORT_35357_TCP_ADDR}:35357/v2.0"

# Configure Keystone Service Catalog
crux user-create -n "${NEUTRON_KEYSTONE_USER}" \
	-p "${NEUTRON_KEYSTONE_PASSWORD}" \
	-t "${ADMIN_TENANT_NAME}" \
	-r admin

crux endpoint-create -n neutron -t network \
	-I "${KEYSTONE_AUTH_PROTOCOL}://${NEUTRON_SERVER_PORT_9696_TCP_ADDR}:9696" \
	-P "${KEYSTONE_AUTH_PROTOCOL}://${MY_IP}:9696" \
	-A "${KEYSTONE_AUTH_PROTOCOL}://${NEUTRON_SERVER_PORT_9696_TCP_ADDR}:9696"

# Database
crudini --set /etc/neutron/neutron.conf \
        database \
        connection \
        "mysql://${NEUTRON_DB_USER}:${NEUTRON_DB_PASSWORD}@${MARIADB_PORT_3306_TCP_ADDR}/${NEUTRON_DB_NAME}"

# Nova
crudini --set /etc/neutron/neutron.conf \
        DEFAULT \
        notify_nova_on_port_status_changes \
        "True"
crudini --set /etc/neutron/neutron.conf \
        DEFAULT \
        notify_nova_on_port_data_changes \
        "True"
crudini --set /etc/neutron/neutron.conf \
        DEFAULT \
        nova_url \
        "http://${NOVA_API_PORT_8774_TCP_ADDR}:8774/v2"
crudini --set /etc/neutron/neutron.conf \
        DEFAULT \
        nova_admin_auth_url \
        "http://${KEYSTONE_ADMIN_PORT_35357_TCP_ADDR}:35357/v2.0"
crudini --set /etc/neutron/neutron.conf \
        DEFAULT \
        nova_region_name \
        "RegionOne"
crudini --set /etc/neutron/neutron.conf \
        DEFAULT \
        nova_admin_username \
        "nova"
crudini --set /etc/neutron/neutron.conf \
        DEFAULT \
        nova_admin_tenant_id \
        "$(keystone tenant-list | grep $ADMIN_TENANT_NAME | awk '{print $2;}')"
crudini --set /etc/neutron/neutron.conf \
        DEFAULT \
        nova_admin_password \
        "${NOVA_ADMIN_PASSWORD}"

# Configure ml2_conf.ini
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini \
        ml2 \
        type_drivers \
        "gre"
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini \
        ml2 \
        tenant_network_types \
        "gre"
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini \
        ml2 \
        mechanism_drivers \
        "openvswitch"
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini \
        ml2_type_gre \
        tunnel_id_ranges \
        "1:1000"
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini \
        securitygroup \
        firewall_driver \
        "neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver"
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini \
        securitygroup \
        enable_security_group \
        "True"

/usr/bin/ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

exec /usr/bin/neutron-server
