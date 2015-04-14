#!/bin/bash

# Docker volumes are based on the container pid. To mount the proper netns,
# a symlink must be created to the netns of the container pid.

ln -s /proc/${NEUTRON_AGENTS_CONTAINER_PID}/ns/net /var/run/netns/${NEUTRON_AGENTS_CONTAINER_PID}
