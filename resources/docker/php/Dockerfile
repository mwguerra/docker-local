FROM php:8.4-fpm-alpine

# Build arguments
ARG XDEBUG_ENABLED=true
ARG UID=1000
ARG GID=1000

# Environment variables
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_HOME=/tmp/composer

# Install system dependencies
RUN apk add --no-cache \
    # Basic tools
    git \
    curl \
    wget \
    bash \
    nano \
    zip \
    unzip \
    # FFmpeg for video/audio processing
    ffmpeg \
    # Libraries for PHP extensions
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libwebp-dev \
    libavif-dev \
    libzip-dev \
    icu-dev \
    oniguruma-dev \
    libxml2-dev \
    libxslt-dev \
    libsodium-dev \
    # PostgreSQL
    postgresql-dev \
    postgresql-client \
    # MySQL client
    mysql-client \
    # ImageMagick
    imagemagick-dev \
    imagemagick \
    # FFI (Foreign Function Interface)
    libffi-dev \
    # For compilation
    linux-headers \
    $PHPIZE_DEPS \
    # GMP (GNU Multiple Precision)
    gmp-dev \
    # LDAP
    openldap-dev \
    # Memcached dependencies
    libmemcached-dev \
    zlib-dev \
    # AMQP (RabbitMQ)
    rabbitmq-c-dev

# Configure and install GD with all image formats
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp \
    --with-avif

# Install essential PHP extensions for Laravel
RUN docker-php-ext-install -j$(nproc) \
    # Database
    pdo \
    pdo_mysql \
    pdo_pgsql \
    mysqli \
    # Images
    gd \
    exif \
    # Compression
    zip \
    # Internationalization
    intl \
    # Strings
    mbstring \
    # XML
    xml \
    dom \
    simplexml \
    xmlwriter \
    xsl \
    soap \
    # Math
    bcmath \
    gmp \
    # System
    opcache \
    pcntl \
    sockets \
    # Others
    ffi \
    sodium \
    calendar \
    gettext \
    shmop \
    sysvmsg \
    sysvsem \
    sysvshm

# Install PECL extensions
RUN pecl install redis && docker-php-ext-enable redis
RUN pecl install imagick && docker-php-ext-enable imagick
RUN pecl install memcached && docker-php-ext-enable memcached
RUN pecl install apcu && docker-php-ext-enable apcu
RUN pecl install amqp && docker-php-ext-enable amqp
RUN pecl install pcov && docker-php-ext-enable pcov
RUN pecl install mongodb && docker-php-ext-enable mongodb
RUN pecl install swoole && docker-php-ext-enable swoole
RUN pecl install protobuf && docker-php-ext-enable protobuf
RUN pecl install grpc && docker-php-ext-enable grpc

# Install Xdebug conditionally
RUN if [ "$XDEBUG_ENABLED" = "true" ]; then \
    pecl install xdebug && docker-php-ext-enable xdebug; \
    fi

# Install Composer (latest version)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Node.js LTS and npm (for Vite, Mix, etc)
RUN apk add --no-cache nodejs npm

# Install Yarn
RUN npm install -g yarn

# Create group and user to avoid permission issues
RUN addgroup -g ${GID} laravel && \
    adduser -D -u ${UID} -G laravel laravel && \
    # Create necessary directories
    mkdir -p /var/www /home/laravel/.composer && \
    chown -R laravel:laravel /var/www /home/laravel

# Working directory settings
WORKDIR /var/www

# Switch to non-root user
USER laravel

EXPOSE 9000

CMD ["php-fpm"]
