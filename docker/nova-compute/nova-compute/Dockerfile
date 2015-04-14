FROM %%KOLLA_NAMESPACE%%/%%KOLLA_PREFIX%%nova-base
MAINTAINER Kolla Project (https://launchpad.net/kolla)

# Install supervisor
RUN easy_install supervisor

# Install supervisor-stdout
RUN pip install supervisor-stdout

# Install required packages
RUN yum -y install openstack-nova-compute \
        sysfsutils \
        && yum clean all

# Create nova directory
RUN mkdir -p /opt/kolla/nova

# Add start scripts
ADD config-nova-compute.sh /opt/kolla/nova/config-nova-compute.sh
ADD nova-start.sh /opt/kolla/nova/nova-start.sh
ADD iscsid-start.sh /opt/kolla/nova/iscsid-start.sh

RUN mkdir -p /var/log/supervisor/
ADD supervisord.conf /etc/

VOLUME [ "/sys/fs/cgroup" ]

# Start supervisor
CMD ["/usr/bin/supervisord"]
