FROM php:8.4-fpm-alpine

# Argumentos de build
ARG XDEBUG_ENABLED=true
ARG UID=1000
ARG GID=1000

# Variáveis de ambiente
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_HOME=/tmp/composer

# Instalar dependências do sistema
RUN apk add --no-cache \
    # Ferramentas básicas
    git \
    curl \
    wget \
    bash \
    nano \
    zip \
    unzip \
    # FFmpeg para processamento de vídeo/áudio
    ffmpeg \
    # Bibliotecas para extensões PHP
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
    # Para compilação
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

# Configurar e instalar extensões GD com todos os formatos de imagem
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp \
    --with-avif

# Instalar extensões PHP essenciais para Laravel
RUN docker-php-ext-install -j$(nproc) \
    # Banco de dados
    pdo \
    pdo_mysql \
    pdo_pgsql \
    mysqli \
    # Imagens
    gd \
    exif \
    # Compressão
    zip \
    # Internacionalização
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
    # Matemática
    bcmath \
    gmp \
    # Sistema
    opcache \
    pcntl \
    sockets \
    # Outros
    ffi \
    sodium \
    calendar \
    gettext \
    shmop \
    sysvmsg \
    sysvsem \
    sysvshm

# Instalar extensões PECL
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

# Instalar Xdebug condicionalmente
RUN if [ "$XDEBUG_ENABLED" = "true" ]; then \
    pecl install xdebug && docker-php-ext-enable xdebug; \
    fi

# Instalar Composer (última versão)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Instalar Node.js LTS e npm (para Vite, Mix, etc)
RUN apk add --no-cache nodejs npm

# Instalar Yarn
RUN npm install -g yarn

# Criar grupo e usuário para evitar problemas de permissão
RUN addgroup -g ${GID} laravel && \
    adduser -D -u ${UID} -G laravel laravel && \
    # Criar diretórios necessários
    mkdir -p /var/www /home/laravel/.composer && \
    chown -R laravel:laravel /var/www /home/laravel

# Configurações de diretório de trabalho
WORKDIR /var/www

# Mudar para usuário não-root
USER laravel

EXPOSE 9000

CMD ["php-fpm"]
