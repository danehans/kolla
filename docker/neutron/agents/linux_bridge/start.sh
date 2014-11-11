#!/bin/bash

set -e

. /opt/kolla/config-neutron.sh

: ${BRIDGE_PHYSICAL_INTERFACE:=eth1}

# Configure ml2_conf.ini
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini \
        ml2 \
        type_drivers \
        "flat,gre"
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
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini \
        ovs \
        enable_tunneling \
        "True"
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini \
        ovs \
        tunnel_type \
        "gre"
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini \
        ovs \
        local_ip \
        "${PUBLIC_IP}"

# Configure OVS
/usr/bin/ovs-vsctl add-br br-int
/usr/bin/ovs-vsctl add-br br-ex
/usr/bin/ovs-vsctl add-port br-ex ${BRIDGE_PHYSICAL_INTERFACE}

# Disable Generic Receive Offload (GRO)
/usr/sbin/ethtool -K ${BRIDGE_PHYSICAL_INTERFACE} gro off

#Initialization scripts expect a symbolic link
/usr/bin/ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

# OS Docs packaging bug reference
/usr/bin/cp /usr/lib/systemd/system/neutron-openvswitch-agent.service \
  /usr/lib/systemd/system/neutron-openvswitch-agent.service.orig
/usr/bin/sed -i 's,plugins/openvswitch/ovs_neutron_plugin.ini,plugin.ini,g' \
  /usr/lib/systemd/system/neutron-openvswitch-agent.service

exec /usr/bin/neutron-openvswitch-agent
