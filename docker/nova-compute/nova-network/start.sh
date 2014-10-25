#!/bin/sh

set -e

. /opt/kolla/config-nova.sh

# Create nova-network flat bridge
cat > /etc/sysconfig/network-scripts/ifcfg-br100 <<EOF
DEVICE="br100"
TYPE="Bridge"
IPADDR="${PUBLIC_IP}"
NETMASK="255.255.255.0"
ONBOOT="yes"
STP="yes"
BOOTPROTO="none"
EOF

# Configure eth0 as a physical bridge interface
sed -i '/^BOOTPROTO=/ s/=.*/="none"/' /etc/sysconfig/network-scripts/ifcfg-eth0
sed -i '$a\DEFROUTE="no"\' /etc/sysconfig/network-scripts/ifcfg-eth0

# Configure eth1 as a physcial interface used for nova-network floating-ips
cat > /etc/sysconfig/network-scripts/ifcfg-eth1 <<EOF
DEVICE="eth1"
BOOTPROTO="none"
ONBOOT="yes"
DEFROUTE="yes"
TYPE="Ethernet"
EOF

# Restart networking for changes to take effect
/sbin/service network restart

# Static route to VXLAN Kube Overlay Network
cat > /etc/sysconfig/network-scripts/route-br100 <<EOF
${BRIDGE_ADDRESS_BASE}.0.0/16 dev br100 scope link src ${PUBLIC_IP}
EOF

# Add bridge and associate flat network interface
/usr/sbin/brctl addbr br100
/usr/sbin/brctl addif br100 eth0

# Start nova-network
exec /usr/bin/nova-network
