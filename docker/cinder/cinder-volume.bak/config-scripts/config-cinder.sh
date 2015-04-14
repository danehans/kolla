#!/bin/bash

set -e

. /opt/kolla/kolla-common.sh
. /opt/kolla/config-cinder.sh

: ${VOLUME_API_LISTEN:="0.0.0.0"}

check_required_vars VOLUME_API_LISTEN ISCSI_HELPER

# IP address on which OpenStack Volume API listens
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        osapi_volume_listen \
        ${VOLUME_API_LISTEN}

# iSCSI target user-land tool to use. tgtadm is default
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        iscsi_helper \
        ${ISCSI_HELPER}

sed -i 's/udev_sync = 1/udev_sync = 0/' /etc/lvm/lvm.conf
sed -i 's/udev_rules = 1/udev_rules = 0/' /etc/lvm/lvm.conf

echo "include /etc/cinder/volumes/*" >> /etc/tgt/tgtd.conf

echo "Starting cinder-volume"
exec /usr/bin/cinder-volume --config-file /etc/cinder/cinder.conf
