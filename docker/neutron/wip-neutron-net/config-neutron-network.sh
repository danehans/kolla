#!/bin/bash

set -e

#. /opt/kolla/kolla-common.sh
. /opt/kolla/config-neutron.sh

: ${OVS_EXTERNAL_BRIDGE_INTERFACE:=eth1}
: ${NEUTRON_KEYSTONE_PASSWORD:=password}

#check_required_vars ADMIN_TENANT_NAME NEUTRON_SHARED_SECRET \
                    NEUTRON_KEYSTONE_PASSWORD \

#check_for_keystone
# TODO add kolla-common neutron-server check
#check_for_neutron_server

# Have DHCP provide reduced MTU size to support tunneling protocol overhead.
cat > /etc/neutron/dnsmasq-neutron.conf <<EOF
dhcp-option-force=26,1454
EOF

# Enable required kernel networking functions
/usr/sbin/sysctl -w net.ipv4.ip_forward=1
/usr/sbin/sysctl -w net.ipv4.conf.all.rp_filter=0
/usr/sbin/sysctl -w net.ipv4.conf.default.rp_filter=0

# l3_agent.ini
crudini --set /etc/neutron/l3_agent.ini \
        DEFAULT \
        verbose \
        "${VERBOSE_LOGGING}"
crudini --set /etc/neutron/l3_agent.ini \
        DEFAULT \
        debug \
        "${DEBUG_LOGGING}"
crudini --set /etc/neutron/l3_agent.ini \
        DEFAULT \
        interface_driver \
        "neutron.agent.linux.interface.OVSInterfaceDriver"
crudini --set /etc/neutron/l3_agent.ini \
        DEFAULT \
        use_namespaces \
        "True"

# dhcp_agent.ini
crudini --set /etc/neutron/dhcp_agent.ini \
        DEFAULT \
        verbose \
        "${VERBOSE_LOGGING}"
crudini --set /etc/neutron/dhcp_agent.ini \
        DEFAULT \
        debug \
        "${DEBUG_LOGGING}"
crudini --set /etc/neutron/dhcp_agent.ini \
        DEFAULT \
        interface_driver \
        "neutron.agent.linux.interface.OVSInterfaceDriver"
crudini --set /etc/neutron/dhcp_agent.ini \
        DEFAULT \
        dhcp_driver \
        "neutron.agent.linux.dhcp.Dnsmasq"
crudini --set /etc/neutron/dhcp_agent.ini \
        DEFAULT \
        use_namespaces \
        "True"
crudini --set /etc/neutron/dhcp_agent.ini \
        DEFAULT \
        dnsmasq_config_file \
        "/etc/neutron/dnsmasq-neutron.conf"

# metadata_agent.ini
crudini --set /etc/neutron/metadata_agent.ini \
        DEFAULT \
        verbose \
        "${VERBOSE_LOGGING}"
crudini --set /etc/neutron/metadata_agent.ini \
        DEFAULT \
        debug \
        "${DEBUG_LOGGING}"
crudini --set /etc/neutron/metadata_agent.ini \
        DEFAULT \
        auth_url \
        "${KEYSTONE_AUTH_PROTOCOL}://${KEYSTONE_PUBLIC_SERVICE_HOST}:5000/v2.0"
crudini --set /etc/neutron/metadata_agent.ini \
        DEFAULT \
        auth_region \
        "RegionOne"
crudini --set /etc/neutron/metadata_agent.ini \
        DEFAULT \
        admin_tenant_name \
        "$ADMIN_TENANT_NAME"
crudini --set /etc/neutron/metadata_agent.ini \
        DEFAULT \
        admin_user \
        "neutron"
crudini --set /etc/neutron/metadata_agent.ini \
        DEFAULT \
        admin_password \
        "${NEUTRON_KEYSTONE_PASSWORD}"
crudini --set /etc/neutron/metadata_agent.ini \
        DEFAULT \
        nova_metadata_ip \
        "${NOVA_API_SERVICE_HOST}"
crudini --set /etc/neutron/metadata_agent.ini \
        DEFAULT \
        nova_metadata_ip \
        "${NEUTRON_SHARED_SECRET}"

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

# TODO Move common ml2 conf to base. Below is unique to net/compute nodes.
# TODO. This config is specific to ovs implementations. Create abstraction layer.
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

## Start OVS
/usr/bin/systemctl openvswitch start
/usr/bin/systemctl enable openvswitch.service

# Configure OVS
/usr/bin/ovs-vsctl add-br br-int
/usr/bin/ovs-vsctl add-br br-ex
/usr/bin/ovs-vsctl add-port br-ex ${OVS_EXTERNAL_BRIDGE_INTERFACE}

# Disable Generic Receive Offload (GRO)
/usr/sbin/ethtool -K ${OVS_EXTERNAL_BRIDGE_INTERFACE} gro off

#TODO Move to neutron-base
/usr/bin/ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini

# OS Docs packaging bug reference
/usr/bin/cp /usr/lib/systemd/system/neutron-openvswitch-agent.service \
  /usr/lib/systemd/system/neutron-openvswitch-agent.service.orig
/usr/bin/sed -i 's,plugins/openvswitch/ovs_neutron_plugin.ini,plugin.ini,g' \
  /usr/lib/systemd/system/neutron-openvswitch-agent.service

## Create required OVS directories
#/usr/bin/mkdir -p /var/run/openvswitch
#/usr/bin/mkdir -p /var/log/openvswitch
#/usr/bin/mkdir -p /etc/openvswitch

## Start OVS
#/usr/sbin/ovsdb-server /etc/openvswitch/conf.db -vconsole:emer -vsyslog:err -vfile:info --remote=punix:/var/run/openvswitch/db.sock --private-key=db:Open_vSwitch,SSL,private_key --certificate=db:Open_vSwitch,SSL,certificate --bootstrap-ca-cert=db:Open_vSwitch,SSL,ca_cert --no-chdir --log-file=/var/log/openvswitch/ovsdb-server.log --pidfile=/var/run/openvswitch/ovsdb-server.pid --detach --monitor

#/usr/sbin/ovs-vswitchd unix:/var/run/openvswitch/db.sock -vconsole:emer -vsyslog:err -vfile:info --mlockall --no-chdir --log-file=/var/log/openvswitch/ovs-vswitchd.log --pidfile=/var/run/openvswitch/ovs-vswitchd.pid --detach --monitor

# Start services
#exec /usr/bin/neutron-openvswitch-agent
#exec /usr/bin/neutron-l3-agent
#exec /usr/bin/neutron-dhcp-agent
#exec /usr/bin/neutron-metadata-agent
