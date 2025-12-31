# ==============================================================================
# PHP 8.4 with AI/ML Tools (Whisper, FFmpeg)
# ==============================================================================
# Extended PHP container with Python and OpenAI Whisper for audio transcription.
# Use with profile 'ai': docker-compose --profile ai up -d
#
# This image is larger (~3GB with models) but provides:
# - OpenAI Whisper for speech-to-text transcription
# - FFmpeg for audio/video processing
# - All standard Laravel PHP extensions
# ==============================================================================

FROM php:8.4-fpm

LABEL maintainer="docker-local"
LABEL description="PHP 8.4 with AI/ML tools (Whisper, FFmpeg) for Laravel applications"

# Build arguments
ARG XDEBUG_ENABLED=false
ARG UID=1000
ARG GID=1000
ARG WHISPER_MODEL=base

# Environment variables
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV COMPOSER_HOME=/tmp/composer
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Build dependencies
    build-essential \
    # FFmpeg for video/audio encoding
    ffmpeg \
    # PostgreSQL client
    libpq-dev \
    postgresql-client \
    # MySQL client
    default-mysql-client \
    # Redis tools
    redis-tools \
    # Image processing
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libavif-dev \
    # ImageMagick
    libmagickwand-dev \
    imagemagick \
    # Zip/compression
    libzip-dev \
    zip \
    unzip \
    # Internationalization
    libicu-dev \
    # XML
    libxml2-dev \
    libxslt1-dev \
    # Sodium
    libsodium-dev \
    # GMP
    libgmp-dev \
    # Process control
    supervisor \
    # Git for composer
    git \
    # Curl for health checks
    curl \
    wget \
    # CA certificates
    ca-certificates \
    # Python for Whisper
    python3 \
    python3-pip \
    python3-venv \
    # Clean up
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

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
    sodium \
    calendar \
    gettext

# Install PECL extensions
RUN pecl install redis && docker-php-ext-enable redis
RUN pecl install imagick && docker-php-ext-enable imagick
RUN pecl install apcu && docker-php-ext-enable apcu

# Install Xdebug conditionally
RUN if [ "$XDEBUG_ENABLED" = "true" ]; then \
    pecl install xdebug && docker-php-ext-enable xdebug; \
    fi

# Install Composer (latest version)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install Node.js 20 LTS
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Whisper in a virtual environment
RUN python3 -m venv /opt/whisper-env \
    && /opt/whisper-env/bin/pip install --upgrade pip \
    && /opt/whisper-env/bin/pip install openai-whisper \
    && ln -s /opt/whisper-env/bin/whisper /usr/local/bin/whisper

# Pre-download Whisper model (optional, uncomment to include in image)
# This adds ~1-2GB to the image but speeds up first transcription
# RUN /opt/whisper-env/bin/python -c "import whisper; whisper.load_model('${WHISPER_MODEL}')"

# Create group and user to avoid permission issues
RUN groupadd -g ${GID} laravel || true && \
    useradd -u ${UID} -ms /bin/bash -g ${GID} laravel || true && \
    mkdir -p /var/www /home/laravel/.composer && \
    chown -R laravel:laravel /var/www /home/laravel

# Copy custom PHP configuration
COPY php-ai.ini /usr/local/etc/php/conf.d/99-ai.ini

# Working directory settings
WORKDIR /var/www

# Switch to non-root user
USER laravel

EXPOSE 9000

CMD ["php-fpm"]
