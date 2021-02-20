FROM php:cli
LABEL maintainer="Adam Volin <ajvolin@gmail.com>"

# environment settings
ENV HOME="/config"

RUN echo "**** install node repo ****" && \
 apt-get update && \
 apt-get install -y gnupg && \
 curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
 echo 'deb https://deb.nodesource.com/node_12.x buster main' \
	> /etc/apt/sources.list.d/nodesource.list && \
 curl -s https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
 echo 'deb https://dl.yarnpkg.com/debian/ stable main' \
	> /etc/apt/sources.list.d/yarn.list && \
 echo "**** install build dependencies ****" && \
 apt-get update && \
 apt-get install -y nodejs && \
 apt-get install -y \
	build-essential \
	libx11-dev \
	libxkbfile-dev \
	libsecret-1-dev \
	pkg-config && \
 echo "**** install runtime dependencies ****" && \
 apt-get install -y \
	git \
	jq \
	nano \
	net-tools \
	sudo \
	yarn \
    locales \
    mosh \
    openconnect \
    openssh-client \
    openssh-server \
    sshuttle \
    wget \
    unzip \
    zip

RUN echo "**** install code-server and composer ****" && \
 curl -fsSL https://code-server.dev/install.sh | sh -s && \
 wget https://raw.githubusercontent.com/composer/getcomposer.org/fa8ea54c9ba4dc3b13111fb4707f9c3b2d4681f6/web/installer -O - -q | php -- --quiet --install-dir=/usr/local/bin --filename=composer && \
 chmod o+x /usr/local/bin/composer && \
 echo "**** clean up ****" && \
 apt-get purge --auto-remove -y \
	build-essential \
	libx11-dev \
	libxkbfile-dev \
	libsecret-1-dev \
	pkg-config && \
 apt-get clean && \
 rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/* && \
    locale-gen "en_US.UTF-8"

RUN chmod o+x /usr/local/bin/composer

# add local files
COPY /root /

# ports and volumes
EXPOSE 8443