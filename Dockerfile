# Use the official PHP image with Apache
FROM php:8.1-apache

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    gettext-base \
    libzip-dev \
    libxml2-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    libssl-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) mbstring xml gd zip

# Copy Composer from the Composer image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set the working directory
WORKDIR /var/www/html

# Copy application files
COPY . /var/www/html/

# Copy template Apache configuration files
COPY 000-default.conf.template /etc/apache2/sites-available/000-default.conf.template
COPY ports.conf.template /etc/apache2/ports.conf.template

# Set the environment variable for the port (provided by Render)
ENV PORT=80

# Substitute environment variables in configuration files
RUN envsubst '${PORT}' < /etc/apache2/ports.conf.template > /etc/apache2/ports.conf && \
    envsubst '${PORT}' < /etc/apache2/sites-available/000-default.conf.template > /etc/apache2/sites-available/000-default.conf

# Install Composer dependencies
RUN composer install --no-dev --optimize-autoloader

# Set permissions
RUN chown -R www-data:www-data /var/www/html

# Enable Apache modules
RUN a2enmod rewrite

# Expose the port specified by the PORT environment variable
EXPOSE ${PORT}

# Start Apache in the foreground
CMD ["apache2-foreground"]
