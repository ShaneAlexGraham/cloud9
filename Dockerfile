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
      org.label-schema.vendor="Shane Graham" \
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
RUN apt update -y \
    && apt install apt-transport-https ca-certificates curl gnupg2 software-properties-common -y \
    && apt-get update -y \
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

# Install docker-compose
RUN sudo curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
RUN sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" -y 
RUN sudo apt update -y 
RUN sudo apt-cache policy docker-ce 
RUN sudo apt install docker-ce -y 

# Install nvm with node and npm
Run echo "***** Install NVM *****" 

RUN mkdir "cloud9"

RUN git clone https://github.com/nvm-sh/nvm.git /root/.nvm

# nvm
RUN echo 'export NVM_DIR="$HOME/.nvm"'                                       >> "$HOME/.bashrc"
RUN echo '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm' >> "$HOME/.bashrc"
RUN echo '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion" # This loads nvm bash_completion' >> "$HOME/.bashrc"

# nodejs and tools
RUN bash -c 'source $HOME/.nvm/nvm.sh   && \
    nvm install node                    && \
    npm install -g doctoc urchin eclint dockerfile_lint && \
    npm install --prefix "$HOME/.nvm/"'

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


# The shell form of CMD is used here to be able to kill NodeJS with CTRL+C (see https://github.com/nodejs/node-v0.x-archive/issues/9131)
CMD node /cloud9/server.js -p 80 -l 0.0.0.0 -w /workspace -a :
