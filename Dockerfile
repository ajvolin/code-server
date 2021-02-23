FROM alpine:3.13
LABEL maintainer="Adam Volin <ajvolin@gmail.com>"

ENV HOME="/config" \
LANGUAGE="en_US.UTF-8" \
LANG="en_US.UTF-8" \
LD_LIBRARY_PATH="/usr/local/instantclient" \
ORACLE_HOME="/usr/local/instantclient" \
PATH=$PATH:/opt/mssql-tools/bin

# Add s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-amd64-installer /tmp/
# Install s6-overlay
RUN chmod +x /tmp/s6-overlay-amd64-installer && \
    /tmp/s6-overlay-amd64-installer /

# Install and configure stage
RUN	mkdir -p \
        /app \
        /config \
        /defaults && \
 	# Install packages
	apk add --no-cache \
		# PHP 8 and Python
		php8 \
		php8-bcmath \
		php8-bz2 \
		php8-ctype \
		php8-curl \
		php8-dom \
		php8-exif \
		php8-fileinfo \
		php8-fpm \
		php8-gd \
		php8-iconv \    
		php8-json \
		php8-ldap \
		php8-mbstring \
		php8-odbc \
		php8-openssl \
		php8-pcntl \
		php8-pdo \
		php8-pdo_sqlite \
		php8-pear \
		php8-phar \
		php8-session \
		php8-sqlite3 \
		php8-tokenizer \
		php8-xml \
		php8-xmlwriter \
		python3 \
		python3-dev \
		py3-pip \
		# Utils
		bash \
		curl \
		git \
		gnupg \
		jq \
		libxml2-dev \
		libpng-dev \
		mosh \
		nano \
		net-tools \
		nodejs \
		npm \
		openconnect \
		openssh \
		shadow \
		sudo \
		tzdata \
		unzip \
		wget \
		zip \
		# Build dependencies
		alpine-sdk \
		autoconf \
		gcc \
		g++ \
		libaio \
		libc6-compat \
		libnsl \
		libsecret-dev \
		libstdc++ \
		libx11-dev \
		libxkbfile-dev \
		make \
		musl-dev \
		php8-dev && \
	# Add mssql drivers
	curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.7.1.1-1_amd64.apk && \
	curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.7.1.1-1_amd64.apk && \
	curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.7.1.1-1_amd64.sig && \
	curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.7.1.1-1_amd64.sig && \
	curl https://packages.microsoft.com/keys/microsoft.asc | \
	gpg --import - && \
	gpg --verify msodbcsql17_17.7.1.1-1_amd64.sig msodbcsql17_17.7.1.1-1_amd64.apk && \
	gpg --verify mssql-tools_17.7.1.1-1_amd64.sig mssql-tools_17.7.1.1-1_amd64.apk && \
	echo y | apk add --no-cache --allow-untrusted msodbcsql17_17.7.1.1-1_amd64.apk \
										mssql-tools_17.7.1.1-1_amd64.apk && \
	# Remove apk cache
	rm -rf /var/cache/apk/* && \

	# Download and unarchive Instant Client v11
	curl -o /tmp/basic.zip https://raw.githubusercontent.com/bumpx/oracle-instantclient/master/instantclient-basic-linux.x64-11.2.0.4.0.zip && \
	curl -o /tmp/sdk.zip https://raw.githubusercontent.com/bumpx/oracle-instantclient/master/instantclient-sdk-linux.x64-11.2.0.4.0.zip && \
	curl -o /tmp/sqlplus.zip https://raw.githubusercontent.com/bumpx/oracle-instantclient/master/instantclient-sqlplus-linux.x64-11.2.0.4.0.zip && \
	unzip -d /usr/local/ /tmp/basic.zip && \
	unzip -d /usr/local/ /tmp/sdk.zip && \
	unzip -d /usr/local/ /tmp/sqlplus.zip && \
	ln -s /usr/local/instantclient_11_2 ${ORACLE_HOME} && \
	ln -s ${ORACLE_HOME}/libclntsh.so.* ${ORACLE_HOME}/libclntsh.so && \
	ln -s ${ORACLE_HOME}/libocci.so.* ${ORACLE_HOME}/libocci.so && \
	ln -s ${ORACLE_HOME}/lib* /usr/lib && \
	ln -s ${ORACLE_HOME}/sqlplus /usr/bin/sqlplus && \
	ln -s /usr/lib/libnsl.so.2.0.0 /usr/lib/libnsl.so.1 && \

	# Add user
	useradd -u 911 -U -d /config -s /bin/bash appuser && \
	# Symlink php8 to php
    ln -sf /usr/bin/php8 /usr/bin/php && \
	ln -sf /usr/bin/pecl8 /usr/bin/pecl && \
	# Install composer
    curl -s https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer | \
    php -- --quiet --install-dir=/usr/local/bin --filename=composer && \
    chmod o+x /usr/local/bin/composer && \
	# Install PHP sqlsrv drivers
	pecl install sqlsrv && \
	pecl install pdo_sqlsrv && \
	echo extension=pdo_sqlsrv.so >> `php --ini | \
		grep "Scan for additional .ini files" | \
		sed -e "s|.*:\s*||"`/10_pdo_sqlsrv.ini && \
	echo extension=sqlsrv.so >> `php --ini | \
		grep "Scan for additional .ini files" | \
		sed -e "s|.*:\s*||"`/00_sqlsrv.ini && \
	# Install OCI8 drivers
	echo "instantclient,${ORACLE_HOME}" | pecl install oci8 && \
	echo extension=oci8.so >> `php --ini | \
		grep "Scan for additional .ini files" | \
		sed -e "s|.*:\s*||"`/30_oci8.ini && \
	# Install sshuttle
    pip3 install sshuttle && \
	# Update npm and install code-server
    npm install -g npm && \
    npm config set python python3 && \
    npm install -g --unsafe-perm code-server && \
	# Cleanup
	apk del alpine-sdk \
		autoconf \
		gcc \
		g++ \
		libaio \
		libc6-compat \
		libsecret-dev \
		libnsl \
		libstdc++ \
		libx11-dev \
		libxkbfile-dev \
		make \
		musl-dev \
		php8-dev && \
  	rm -rf /tmp/*.zip /tmp/pear/

# Copy s6 config files
COPY root/ /

# Expose port 8443
EXPOSE 8443

# Register entry point
ENTRYPOINT ["/init"]
