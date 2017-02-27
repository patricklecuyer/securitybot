FROM python:2.7

COPY . /securitybot

USER securitybot

env PYTHONPATH $PYTHONPATH:/securitybot

RUN apt-get update && \
    apt-get install -y mysql-client && \
    pip install -r /securitybot/requirements.txt

WORKDIR /securitybot

ENTRYPOINT ["/securitybot/docker_entrypoint.sh"]
