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
# Install and configure
RUN chmod +x /tmp/s6-overlay-amd64-installer && \
    /tmp/s6-overlay-amd64-installer / && \
	mkdir -p \
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
		php8-dev \
		php8-dom \
		php8-exif \
		php8-fileinfo \
		php8-ftp \
		php8-gd \
		php8-gettext \
		php8-iconv \  
		php8-imap \  
		php8-json \
		php8-ldap \
		php8-mbstring \
		php8-mysqli \
		php8-odbc \
		php8-openssl \
		php8-pcntl \
		php8-pdo \
		php8-pdo_mysql \
		php8-pdo_pgsql \
		php8-pdo_sqlite \
		php8-pear \
		php8-phar \
		php8-phpdbg \
		php8-pgsql \
		php8-session \
		php8-simplexml \
		php8-soap \
		php8-sockets \
		php8-sqlite3 \
		php8-tidy \
		php8-tokenizer \
		php8-xml \
		php8-xmlreader \
		php8-xmlwriter \
		php8-xsl \
		php8-zip \
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
		unixodbc-dev \
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
		musl-dev && \

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
	curl -o /tmp/basic.zip https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-basic-linux.x64-21.1.0.0.0.zip && \
	curl -o /tmp/sdk.zip https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-sdk-linux.x64-21.1.0.0.0.zip && \
	curl -o /tmp/sqlplus.zip https://download.oracle.com/otn_software/linux/instantclient/211000/instantclient-sqlplus-linux.x64-21.1.0.0.0.zip && \
	unzip -d /usr/local/ /tmp/basic.zip && \
	unzip -d /usr/local/ /tmp/sdk.zip && \
	unzip -d /usr/local/ /tmp/sqlplus.zip && \
	ln -sf /usr/local/instantclient_21_1 ${ORACLE_HOME} && \
	ln -sf ${ORACLE_HOME}/libclntsh.so.* ${ORACLE_HOME}/libclntsh.so && \
	ln -sf ${ORACLE_HOME}/libocci.so.* ${ORACLE_HOME}/libocci.so && \
	ln -sf ${ORACLE_HOME}/lib* /usr/lib && \
	ln -sf ${ORACLE_HOME}/sqlplus /usr/bin/sqlplus && \
	ln -sf /usr/lib/libnsl.so.2.0.1 /usr/lib/libnsl.so.1 && \
    ln -sf /lib/libc.so.6 /usr/lib/libresolv.so.2 && \
	ln -sf /lib64/ld-linux-x86-64.so.2 /usr/lib/ld-linux-x86-64.so.2 && \

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
  	rm -rf /tmp/*.zip /tmp/pear/ /msodbc* /mssql-tools*

# Copy s6 config files
COPY root/ /

# Expose port 8443
EXPOSE 8443

# Register entry point
ENTRYPOINT ["/init"]

# Register healthcheck
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8443/healthz
