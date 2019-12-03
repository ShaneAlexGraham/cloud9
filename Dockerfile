FROM debian:buster-slim
COPY files/  /

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



# replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Set debconf to run non-interactively
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# update the repository sources list
# and install dependencies
RUN apt-get update \
    && apt-get install -y curl tmux locales  \
    && apt-get -y autoclean

                                                                                
#Install base packages needed for later isntalls
RUN echo "\n\n\n***** Install base packages *****\n"      
RUN apt-get update && apt-get install -y -q --no-install-recommends \
      nano \
      openssl \
      python \
      sshfs \
      apt-transport-https \
      build-essential \
      ca-certificates \
      curl \
      git \
      libssl-dev \
      sudo \
      wget
      
RUN rm -rf /var/lib/apt/lists/* && update-ca-certificates;
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen
RUN locale-gen

# Install nvm with node and npm
Run echo "***** Install NVM *****" 


# Install docker compose
Run echo "***** Docker Compose *****" 
Run curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
Run chmod +x /usr/local/bin/docker-compose

# nvm environment variables
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 13.2.0

# install nvm
# https://github.com/creationix/nvm#install-script
RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.2/install.sh | bash

# install node and npm
RUN source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# confirm installation
RUN node -v
RUN npm -v

#Install Cloud9
RUN echo "\n\n\n***** Install Cloud9 *****\n"                                                                                  && \
    git clone https://github.com/c9/core.git /cloud9                                                                           && \
    cd /cloud9                                                                                                                 && \
    scripts/install-sdk.sh;
    
Run echo "\n\n\n***** Clean the packages *****\n"  \
    && apt-get -y autoremove --purge python build-essential  \
    && apt-get -y autoclean  \
    && apt-get -y clean;
    
Run echo -e "\n\n\n*********************************************\n\n"

# Customization
RUN ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime      ; \
    echo "America/Toronto" > /etc/timezone                      ; \
    chmod 644 /etc/bash.bashrc                                  ; \
    chmod u=rwX,g=,o= -R /workspace                             ;

    
EXPOSE 80
VOLUME /workspace
WORKDIR /cloud9


# The shell form of CMD is used here to be able to kill NodeJS with CTRL+C (see https://github.com/nodejs/node-v0.x-archive/issues/9131)
CMD node /cloud9/server.js -p 80 -l 0.0.0.0 -w /workspace -a :
