#!/bin/sh

set -e

. /opt/kolla/nova/config-nova-compute.sh

sleep 6

echo "Starting nova-compute."
exec /usr/bin/nova-compute
