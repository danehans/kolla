#!/bin/bash

set -e

. /opt/kolla/kolla-common.sh
. /opt/kolla/config-cinder.sh

echo "Starting cinder-scheduler"
exec /usr/bin/cinder-scheduler
