FROM kollaglue/fedora-rdo-neutron-base:l3_ovs_wip
MAINTAINER Kolla Project (https://launchpad.net/kolla)

#Install required packages
RUN yum install -y openstack-neutron \
        openstack-neutron-openvswitch \
        ethtool \
        ; yum clean all

VOLUME /var/lib/neutron
VOLUME /var/lib/openvswitch

#ADD ./start.sh /start.sh
ADD ./config-neutron-network.sh /config-neutron-network.sh
ADD ./check.sh /check.sh

RUN ./config-neutron-network.sh

RUN systemctl enable neutron-openvswitch-agent.service neutron-l3-agent.service neutron-dhcp-agent.service neutron-metadata-agent.service

CMD ["/usr/sbin/init"]
#CMD ["/start.sh"]
