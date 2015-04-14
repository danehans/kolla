FROM %%KOLLA_NAMESPACE%%/%%KOLLA_PREFIX%%cinder-base
MAINTAINER Kolla Project (https://launchpad.net/kolla)

# Install supervisor
RUN easy_install supervisor

# Install supervisor-stdout
RUN pip install supervisor-stdout

# Install required packages
#RUN yum install -y scsi-target-utils lsscsi lvm2 && yum clean all
#RUN yum install -y lvm2 targetcli targetd && yum clean all
#RUN yum install -y lvm2 targetcli scsi-target-utils && yum clean all
#RUN yum install -y lvm2 targetcli && yum clean all
RUN yum install -y lvm2 scsi-target-utils && yum clean all

# Create cinder directory
RUN mkdir -p /opt/kolla/cinder

# Add start scripts
ADD start-scripts/tgt.sh /opt/kolla/cinder/
#ADD start-scripts/target.sh /opt/kolla/cinder/
#ADD start-scripts/targetd.sh /opt/kolla/cinder/
#ADD start-scripts/tgt-post-start.sh /opt/kolla/cinder/
#ADD start-scripts/lvmetad.sh /opt/kolla/cinder/
ADD start-scripts/volume.sh /opt/kolla/cinder/

# Configure supervisord
RUN mkdir -p /var/log/supervisor/
ADD supervisord.conf /etc/

# Start supervisor
CMD ["/usr/bin/supervisord"]
