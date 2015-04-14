FROM %%KOLLA_NAMESPACE%%/%%KOLLA_PREFIX%%cinder-base
MAINTAINER Kolla Project (https://launchpad.net/kolla)

RUN yum install -y lvm2 targetcli \
                scsi-target-utils lsscsi

ADD ./start.sh /start.sh

CMD ["/start.sh"]
