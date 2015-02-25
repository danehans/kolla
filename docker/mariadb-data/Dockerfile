FROM %%KOLLA_NAMESPACE%%/%%KOLLA_PREFIX%%base
MAINTAINER Kolla Project (https://launchpad.net/kolla)

# Create the DIRs used by the data volume
RUN mkdir -p /var/lib/mysql
RUN mkdir -p /var/log/mariadb

# Command needed to start the data container.
# Note: data containers do not need to be persistent.
CMD ["/bin/sh"]
