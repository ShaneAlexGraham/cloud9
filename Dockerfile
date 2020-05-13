FROM ubuntu:19.10

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
      org.label-schema.vendor="Shane Graham" \
      org.label-schema.version="1.0" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.docker.cmd="docker run --rm --name cloud9 -p 80:80 shanealexgraham/cloud9:latest"	\
      org.label-schema.docker.cmd.devel="docker run --rm --name cloud9 -p 80:80 shanealexgraham/cloud9:latest" \
      org.label-schema.docker.debug="docker run --rm --name cloud9 -it -p 80:80 shanealexgraham/cloud9:latest bash"	



# replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt update -y \
    && apt install apt-transport-https ca-certificates curl gnupg2 software-properties-common -y \
    && apt-get update -y \
    && apt-get install -y curl tmux locales  \
    && apt-get -y autoclean \
    && apt-get install sudo snapd -y 
                               
RUN adduser --disabled-password --gecos '' docker
RUN adduser docker sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN sudo apt install apt-transport-https dirmngr -y
RUN sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF

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

# Install docker-compose
RUN curl -fsSL https://get.docker.com -o get-docker.sh
RUN sudo sh get-docker.sh

# Install nvm with node and npm
Run echo "***** Install NVM *****" 

# install nvm
# https://github.com/creationix/nvm#install-script
RUN mkdir -p /usr/local/nvm

# nvm environment variables
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 13.3.0

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash
ENV NVM_DIR /usr/local/nvm


ENV NODE_PATH $NVM_DIR/lib/node_modules
ENV PATH $NVM_DIR/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH

# install node and npm
RUN source $NVM_DIR/nvm.sh \
   && nvm install $NODE_VERSION \
   && nvm alias default $NODE_VERSION \
   && nvm use default
   
#Install Cloud9
RUN echo "\n\n\n***** Install Cloud9 *****\n"                                                                                  && \
    git clone https://github.com/c9/core.git /cloud9                                                                           && \
    cd /cloud9                                                                                                                 && \
    scripts/install-sdk.sh;
    
Run echo "\n\n\n***** Clean the packages *****\n"  \
    && sudo apt-get -y autoremove --purge python build-essential  \
    && sudo apt-get -y autoclean  \
    && sudo apt-get -y clean;
    
Run echo -e "\n\n\n*********************************************\n\n"

# Customization
RUN sudo ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime      ; \
    sudo echo "America/Toronto" > /etc/timezone                      ; \
    sudo chmod 644 /etc/bash.bashrc                                  ; \
    sudo chmod u=rwX,g=,o= -R /workspace                             ;

EXPOSE 80
VOLUME /workspace
WORKDIR /cloud9

RUN source $NVM_DIR/nvm.sh && nvm --version
RUN source $NVM_DIR/nvm.sh && npm install typescript -g

RUN sudo service docker start

# The shell form of CMD is used here to be able to kill NodeJS with CTRL+C (see https://github.com/nodejs/node-v0.x-archive/issues/9131)
CMD source $NVM_DIR/nvm.sh && node /cloud9/server.js -p 80 -l 0.0.0.0 -w /workspace -a :
