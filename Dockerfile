FROM python:2.7

COPY . /securitybot

ENV PYTHONPATH $PYTHONPATH:/securitybot

RUN apt-get update 
RUN    apt-get install -y mysql-client
RUN    pip install -r /securitybot/requirements.txt
RUN    useradd -N -s '/bin/false' -e '' securitybot

USER securitybot

WORKDIR /securitybot

ENTRYPOINT ["/securitybot/docker_entrypoint.sh"]
