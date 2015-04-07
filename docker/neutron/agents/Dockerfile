FROM %%KOLLA_NAMESPACE%%/%%KOLLA_PREFIX%%neutron-base
MAINTAINER Kolla Project (https://launchpad.net/kolla)

# Install supervisor
RUN easy_install supervisor

# Install supervisor-stdout
RUN pip install supervisor-stdout

# Configure supervisord
RUN mkdir -p /var/log/supervisor/
ADD supervisord.conf /etc/

# Install required packages
RUN yum install -y openstack-neutron-openvswitch \
        openstack-neutron \
        && yum clean all

# Ensure ovs directories are present
RUN mkdir -p /etc/openvswitch
RUN mkdir -p /var/run/openvswitch

# Add config scripts
ADD config-scripts/config-ovs.sh /opt/kolla/openvswitch/
ADD config-scripts/config-ovs-agent.sh /opt/kolla/neutron/
ADD config-scripts/config-dhcp-agent.sh /opt/kolla/neutron/
ADD config-scripts/config-l3-agent.sh /opt/kolla/neutron/
ADD config-scripts/config-metadata-agent.sh /opt/kolla/neutron/
ADD config-scripts/config-sudoers.sh /opt/kolla/

# Add check scripts
ADD check-scripts/check-ovs-agent.sh /opt/kolla/neutron/
ADD check-scripts/check-dhcp-agent.sh /opt/kolla/neutron/
ADD check-scripts/check-l3-agent.sh /opt/kolla/neutron/
ADD check-scripts/check-metadata-agent.sh /opt/kolla/neutron/

# Start supervisor
CMD ["/usr/bin/supervisord"]
