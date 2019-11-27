FROM debian:buster-slim

MAINTAINER Shane Graham <shane.alex.graham@gmail.com>

# http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Cloud9" \
      org.label-schema.description="Docker image for standalone Cloud9 (c9.io)" \
      org.label-schema.url="https://github.com/ShaneAlexGraham/cloud9" \
      org.label-schema.usage="https://github.com/ShaneAlexGraham/cloud9/blob/master/README.md" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/ShaneAlexGraham/cloud9" \
      org.label-schema.vendor="Shane GRaham" \
      org.label-schema.version="1.0" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.docker.cmd="docker run --rm --name cloud9 -p 80:80 shanealexgraham/cloud9:latest"	\
      org.label-schema.docker.cmd.devel="docker run --rm --name cloud9 -p 80:80 shanealexgraham/cloud9:latest" \
      org.label-schema.docker.debug="docker run --rm --name cloud9 -it -p 80:80 shanealexgraham/cloud9:latest bash"	


# Installation
RUN echo "\n\n\n***** Upgrade system *****\n"                                                                           && \
    export DEBIAN_FRONTEND=noninteractive                                                                               && \
    apt-get update && apt-get -y dist-upgrade                                                                           && \
    apt-get install sudo -y                                                                                             && \
    \
    echo "\n\n\n***** Install some packages for Cloud9 *****\n"                                                         && \
    apt-get install -y --no-install-recommends nano git wget curl openssl ca-certificates build-essential python sshfs  && \
    update-ca-certificates                                                                                              && \
    \
    echo "\n\n\n***** Install Cloud9 *****\n"                                                                           && \
    git clone https://github.com/c9/core.git /cloud9                                                                    && \
    cd /cloud9                                                                                                          && \
    scripts/install-sdk.sh                                                                                              && \
    \
    echo "\n\n\n***** Make the NodeJS installed with Cloud9 available (WARNING: it is an old version) *****\n"          && \
    ln -s /root/.c9/node/bin/node /usr/bin/node                                                                         && \
    \
    echo "\n\n\n***** Clean the packages *****\n"                                                                       && \
    apt-get -y autoremove --purge python build-essential                                                                && \
    apt-get -y autoclean                                                                                                && \
    apt-get -y clean                                                                                                    && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*                                                                       && \
    \
    echo -e "\n\n\n*********************************************\n\n"

# Customization
COPY files/  /
RUN ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime  ; \
    echo "America/Toronto" > /etc/timezone                     ; \
    chmod 644 /etc/bash.bashrc                              ; \
    chmod u=rwX,g=,o= -R /workspace

    
EXPOSE 80
VOLUME /workspace
WORKDIR /cloud9


# The shell form of CMD is used here to be able to kill NodeJS with CTRL+C (see https://github.com/nodejs/node-v0.x-archive/issues/9131)
CMD node /cloud9/server.js -p 80 -l 0.0.0.0 -w /workspace -a :
