FROM kollaglue/fedora-rdo-base
MAINTAINER Kolla Project (https://launchpad.net/kolla)

# Install packages
RUN yum -y install openstack-glance && yum clean all

# Copy config script
COPY config-glance.sh /opt/kolla/config-glance.sh
