FROM kollaglue/fedora-rdo-base
MAINTAINER Kolla Project (https://launchpad.net/kolla)

#Install required packages
RUN yum install -y openstack-keystone \
	python-keystoneclient \
	; yum clean all

# Add start-up and check scripts
ADD ./start.sh /opt/kolla/start.sh
ADD ./check.sh /opt/kolla/check.sh

# Run the Keystone start script
CMD ["/opt/kolla/start.sh"]
