#!/bin/bash

set -e

. /opt/kolla/kolla-common.sh
. /opt/kolla/config-cinder.sh

: ${VOLUME_API_LISTEN:="0.0.0.0"}

check_required_vars VOLUME_API_LISTEN ISCSI_HELPER ISCSI_IP_ADDRESS

cfg=/etc/cinder/cinder.conf

# Logging
crudini --set $cfg \
        DEFAULT \
        log_file \
        "${CINDER_VOLUME_LOG_FILE}"

# IP address on which OpenStack Volume API listens
crudini --set $cfg \
        DEFAULT \
        osapi_volume_listen \
        "${VOLUME_API_LISTEN}"

# The IP address that the iSCSI daemon is listening on
crudini --set $cfg \
        DEFAULT \
        iscsi_ip_address \
        "${ISCSI_IP_ADDRESS}"

# Set to false when using loopback devices (testing)
crudini --set $cfg \
        DEFAULT \
        secure_delete \
        "false"

## iSCSI target user-land tool to use. tgtadm is default
#crudini --set $cfg \
#        DEFAULT \
#        iscsi_helper \
#        "${ISCSI_HELPER}"

### TEST ###
crudini --set $cfg \
        DEFAULT \
        enabled_backends \
        "lvm57"

crudini --set $cfg \
        lvm57 \
        iscsi_helper \
        "${ISCSI_HELPER}"

crudini --set $cfg \
        lvm57 \
        volume_group \
        "cinder-volumes57"

crudini --set $cfg \
        lvm57 \
        volume_driver \
        "cinder.volume.drivers.lvm.LVMISCSIDriver"

crudini --set $cfg \
        lvm57 \
        iscsi_ip_address \
        "${ISCSI_IP_ADDRESS}"

crudini --set $cfg \
        lvm57 \
        volume_backend_name \
        "LVM_iSCSI57"

sed -i 's/udev_sync = 1/udev_sync = 0/' /etc/lvm/lvm.conf
sed -i 's/udev_rules = 1/udev_rules = 0/' /etc/lvm/lvm.conf
sed -i 's/use_lvmetad = 1/use_lvmetad = 0/' /etc/lvm/lvm.conf

# For lioadm iscsi_helper
#echo "Starting Restore LIO kernel target configuration"
#/usr/bin/targetctl restore

echo "Starting cinder-volume"
exec /usr/bin/cinder-volume --config-file /etc/cinder/cinder.conf
