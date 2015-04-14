#!/bin/sh

modprobe iscsi_tcp

echo "Starting iscsid."
exec /usr/sbin/iscsid -d 8 -f
