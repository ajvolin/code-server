FROM php:cli

# set version label
ARG BUILD_DATE
ARG VERSION
ARG CODE_RELEASE
LABEL build_version="ajvolin version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="Adam Volin <ajvolin@gmail.com>"

# environment settings
ENV HOME="/config"

RUN \
 echo "**** install node repo ****" && \
 apt-get update && \
 apt-get install -y \
	gnupg && \
 curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
 echo 'deb https://deb.nodesource.com/node_12.x buster main' \
	> /etc/apt/sources.list.d/nodesource.list && \
 curl -s https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
 echo 'deb https://dl.yarnpkg.com/debian/ stable main' \
	> /etc/apt/sources.list.d/yarn.list && \
 echo "**** install build dependencies ****" && \
 apt-get update && \
 apt-get install -y \
	build-essential \
	libx11-dev \
	libxkbfile-dev \
	libsecret-1-dev \
	pkg-config && \
 echo "**** install runtime dependencies ****" && \
 apt-get purge --auto-remove -y npm && \
 apt-get install -f -y \
	git \
	jq \
	nano \
	net-tools \
	sudo \
	yarn \
    locales \
    mosh \
    nodejs-dev \
    openconnect \
    openssh-client \
    openssh-server \
    sshuttle \
    wget \
    unzip \
    zip && \
 echo "**** install code-server ****" && \
 if [ -z ${CODE_RELEASE+x} ]; then \
	CODE_RELEASE=$(curl -sX GET "https://api.github.com/repos/cdr/code-server/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]'); \
 fi && \
 CODE_VERSION=$(echo "$CODE_RELEASE" | awk '{print substr($1,2); }') && \
 yarn config set network-timeout 600000 -g && \
 yarn --production --verbose --frozen-lockfile global add code-server@"$CODE_VERSION" && \
 yarn cache clean && \
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
    locale-gen "en_US.UTF-8" && \
    wget https://raw.githubusercontent.com/composer/getcomposer.org/fa8ea54c9ba4dc3b13111fb4707f9c3b2d4681f6/web/installer -O - -q | php -- --quiet --install-dir=/usr/local/bin --filename=composer

RUN chmod o+x /usr/local/bin/composer

# add local files
COPY /root /

# ports and volumes
EXPOSE 8443