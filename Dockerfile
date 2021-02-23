FROM alpine:3.13
LABEL maintainer="Adam Volin <ajvolin@gmail.com>"

ENV HOME="/config" \
LANGUAGE="en_US.UTF-8" \
LANG="en_US.UTF-8"

# Add s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer && \
    /tmp/s6-overlay-amd64-installer /

# Update apk and add dependencies
RUN apk add --update --no-cache \
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
                        php8-mbstring \
                        php8-openssl \
                        php8-pcntl \
                        php8-pdo \
                        php8-pdo_sqlite \
                        php8-phar \
                        php8-session \
                        php8-sqlite3 \
                        php8-tokenizer \
                        php8-xml \
                        php8-xmlwriter \
                        python3 \
						python3-dev \
						py3-pip \
                        curl \
                        git \
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
                        oniguruma-dev \
						shadow \
                        sudo \
                        tzdata \
                        unzip \
                        wget \
                        zip \
                        alpine-sdk \
                        bash \
                        libstdc++ \
                        libc6-compat \
                        libx11-dev \
                        libxkbfile-dev \
                        libsecret-dev && \
    rm -rf /var/cache/apk/*

# Setup
RUN useradd -u 911 -U -d /config -s /bin/false appuser && \
    mkdir -p \
        /app \
        /config \
        /defaults && \
    mv /usr/bin/with-contenv /usr/bin/with-contenvb && \
    ln -sf /usr/bin/php8 /usr/bin/php && \
    wget https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer -O - -q | \
    php -- --quiet --install-dir=/usr/local/bin --filename=composer && \
    chmod o+x /usr/local/bin/composer && \
    pip3 install sshuttle && \
    npm install -g npm && \
    npm config set python python3 && \
    npm install -g --unsafe-perm code-server

# Copy s6 config files
COPY root/ /

# Expose port 8443
EXPOSE 8443

# Register entry point
ENTRYPOINT ["/init"]
