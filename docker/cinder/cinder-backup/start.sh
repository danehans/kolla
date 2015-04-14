#!/bin/bash

set -e

. /opt/kolla/kolla-common.sh
. /opt/kolla/config-cinder.sh

: ${BACKUP_DRIVER:= cinder.backup.drivers.swift}
: ${BACKUP_MANAGER:= cinder.backup.manager.BackupManager}
: ${BACKUP_API_CLASS:= cinder.backup.api.API}
: ${BACKUP_NAME_TEMPLATE:= backup-%s}

#-----Cinder.conf setup-----

# control_exchange
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        control_exchange \
        "openstack"

# volume backups
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        backup_driver \
        "${BACKUP_DRIVER}"
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        backup_topic \
        "cinder-backup"
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        backup_manager \
        "${BACKUP_MANAGER}"
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        backup_api_class \
        "${BACKUP_API_CLASS}"
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        backup_name_template \
        "${BACKUP_NAME_TEMPLATE}"
crudini --set /etc/cinder/cinder.conf \
        DEFAULT \
        volume_backup_name \
        "DEFAULT"

echo "Starting cinder-backup"
exec /usr/bin/cinder-backup
