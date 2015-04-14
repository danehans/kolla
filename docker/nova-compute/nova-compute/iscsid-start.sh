#!/bin/sh

set -e

echo "Starting iscsid"
exec /usr/sbin/iscsid -d 8 -f
