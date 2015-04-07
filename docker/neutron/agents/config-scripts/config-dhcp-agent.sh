#!/bin/bash

set -e

. /opt/kolla/config-neutron.sh
. /opt/kolla/config-sudoers.sh

: ${INTERFACE_DRIVER:=neutron.agent.linux.interface.OVSInterfaceDriver}
: ${DHCP_DRIVER:=neutron.agent.linux.dhcp.Dnsmasq}
: ${USE_NAMESPACES:=true}
: ${DELETE_NAMESPACES:=true}
: ${DNSMASQ_CONFIG_FILE:=/etc/neutron/dnsmasq-neutron.conf}

cfg=/etc/neutron/dhcp_agent.ini
neutron_conf=/etc/neutron/neutron.conf

# Logging
crudini --set $neutron_conf \
        DEFAULT \
        log_file \
        "${NEUTRON_DHCP_AGENT_LOG_FILE}"

# Configure dhcp_agent.ini
crudini --set $cfg \
        DEFAULT \
        verbose \
        "${VERBOSE_LOGGING}"
crudini --set $cfg \
        DEFAULT \
        debug \
        "${DEBUG_LOGGING}"
crudini --set $cfg \
        DEFAULT \
        interface_driver \
        "${INTERFACE_DRIVER}"
crudini --set $cfg \
        DEFAULT \
        dhcp_driver \
        "${DHCP_DRIVER}"
crudini --set $cfg \
        DEFAULT \
        use_namespaces \
        "${USE_NAMESPACES}"
crudini --set $cfg \
        DEFAULT \
        delete_namespaces \
        "${DELETE_NAMESPACES}"
crudini --set $cfg \
        DEFAULT \
        dnsmasq_config_file \
        "${DNSMASQ_CONFIG_FILE}"
crudini --set $cfg \
        DEFAULT \
        root_helper \
        "sudo neutron-rootwrap /etc/neutron/rootwrap.conf"

cat > ${DNSMASQ_CONFIG_FILE} <<EOF
dhcp-option-force=26,1454
EOF

# Start DHCP Agent
#exec /usr/bin/neutron-dhcp-agent --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/dhcp_agent.ini
