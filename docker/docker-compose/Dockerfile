FROM debian:wheezy
RUN apt-get update -qq && apt-get install -qy python python-pip python-dev git && apt-get clean
RUN useradd -d /home/user -m -s /bin/bash user
WORKDIR /code/

# Custom ENVs for Kolla
ENV COMPOSE_PROJECT_NAME kollaglue-fedora-rdo
ENV COMPOSE_FILE /opt/docker-compose/docker-compose.yml

ADD requirements.txt /code/
RUN pip install -r requirements.txt

ADD requirements-dev.txt /code/
RUN pip install -r requirements-dev.txt

ADD . /code/
RUN python setup.py install

RUN chown -R user /code/

# Talk to docker API on host instead of exposing through TCP
VOLUME /var/run/docker.sock

# Directory for Kolla yaml's
VOLUME /opt/docker-compose

ENTRYPOINT ["/usr/local/bin/docker-compose"]
