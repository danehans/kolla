#!/bin/sh

RES=0

if ! /usr/bin/ovs-vsctl show; then
    echo "ERROR: ovs-vsctl show failed" >&2
    RES=1
fi

exit $RES
