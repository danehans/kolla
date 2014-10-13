FROM danehans/fedora-rdo-base
MAINTAINER Daneyon Hansen <danehans@cisco.com>

RUN yum -y install dnf dnf-plugins-core; yum clean all
RUN dnf copr enable -y larsks/crux
RUN yum -y install \
        openstack-neutron-ml2 \
        python-keystoneclient \
        crux \
	; yum clean all

RUN mkdir /opt/neutron
COPY config-neutron.sh /opt/neutron/config-neutron.sh

