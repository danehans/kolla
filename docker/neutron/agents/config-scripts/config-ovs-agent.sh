#!/bin/bash

set -e

. /opt/kolla/config-neutron.sh
. /opt/kolla/config-sudoers.sh

: ${NEUTRON_FLAT_NETWORK_NAME:=physnet1}
: ${NEUTRON_FLAT_NETWORK_BRIDGE:=br-ex}
: ${NEUTRON_FLAT_NETWORK_INTERFACE:=eth1}

check_required_vars PUBLIC_IP

neutron_cfg=/etc/neutron/neutron.conf
ml2_cfg=/etc/neutron/plugins/ml2/ml2_conf.ini

# Logging
crudini --set $neutron_cfg \
        DEFAULT \
        log_file \
        "${NEUTRON_OPENVSWITCH_AGENT_LOG_FILE}"

# Configure ml2_conf.ini
if [[ ${TYPE_DRIVERS} =~ .*vxlan.* ]]; then
  crudini --set $ml2_cfg \
          ovs \
          local_ip \
          "${PUBLIC_IP}"
fi

if [[ ${TYPE_DRIVERS} =~ .*vxlan.* ]] || [[ ${TYPE_DRIVERS} =~ .*gre.* ]]; then
crudini --set $ml2_cfg \
        ovs \
        enable_tunneling \
        "True"
fi

crudini --set $ml2_cfg \
        ovs \
        bridge_mappings \
        "${NEUTRON_FLAT_NETWORK_NAME}:${NEUTRON_FLAT_NETWORK_BRIDGE}"
crudini --set $ml2_cfg \
        securitygroup \
        firewall_driver \
        "neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver"

# Create external bridge
ovs-vsctl add-br ${NEUTRON_FLAT_NETWORK_BRIDGE}

# Add physical port to external bridge
ovs-vsctl add-port ${NEUTRON_FLAT_NETWORK_BRIDGE} ${NEUTRON_FLAT_NETWORK_INTERFACE} 
