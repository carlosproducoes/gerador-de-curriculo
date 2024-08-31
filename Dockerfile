# Use the official PHP 8.2 image as the base image
FROM php:8.2

# Set time zone
ENV TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN printf '[Date]\ndate.timezone="%s"\n', $TZ > /usr/local/etc/php/conf.d/tzone.ini

# Install dependencies
RUN apt-get update && apt-get install -y \
    libzip-dev \
    vim \
    zip \
    curl \
    gnupg \
    && docker-php-ext-configure zip \
    && docker-php-ext-install zip pdo_mysql

# Install Node.js 
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install nodejs -y
# Set the working directory in the container
WORKDIR /var/www/html

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy the rest of your application code
COPY . .

# Install Laravel dependencies using Composer
RUN composer install --no-scripts --no-autoloader

# Install npm dependencies
COPY package.json ./
RUN npm install

# Copy the .env.example to .env
COPY .env.example .env

# Add some alias
RUN echo 'alias a="php artisan"' >> ~/.bashrc

# Generate application key
RUN php artisan key:generate

# Fix permissions for the application directory
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && npm cache clean --force

# Expose port 80 to the host
EXPOSE 80

# Start the Laravel application
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=80"]