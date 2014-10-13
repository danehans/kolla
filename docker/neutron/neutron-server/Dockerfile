FROM danehans/fedora-rdo-neutron-base
MAINTAINER Daneyon Hansen <danehans@cisco.com>

#Install required packages
RUN yum install -y openstack-neutron \
        openstack-neutron-ml2 \
        python-neutronclient \
        mariadb \
        ; yum clean all

EXPOSE 9696

ADD ./start.sh /start.sh
CMD ["/start.sh"]
