FROM kollaglue/fedora-rdo-neutron-base:l3_ovs_wip
MAINTAINER Kolla Project (https://launchpad.net/kolla)

#Install required packages
RUN yum install -y openstack-neutron \
        openstack-neutron-linuxbridge \
        yum clean all;

ADD ./start.sh /start.sh
ADD ./check.sh /check.sh

CMD ["/start.sh"]
