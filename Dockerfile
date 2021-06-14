FROM php:7.4-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
	git \
	curl \
	libpng-dev \
	libonig-dev \
	libxml2-dev \
	libzip-dev \
	zip \
	unzip \
	nginx \
	supervisor \
	cron

# Install Google Chrome (uncomment, if you need it)
#RUN apt-get update && apt-get install -y \
#	google-chrome-stable \
#	python3 \
#	python3-pip
#RUN wget -O /tmp/chromedriver.zip http://chromedriver.storage.googleapis.com/`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE`/chromedriver_linux64.zip
#RUN unzip /tmp/chromedriver.zip chromedriver -d /usr/local/bin/
#RUN pip3 install selenium

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install \
	intl \
	pdo \
	pdo_mysql \
	mbstring \
	exif \
	pcntl \
	bcmath \
	gd

# Install PHP intl extension
RUN docker-php-ext-configure intl \
	&& docker-php-ext-install intl

# Install PHP zip extension
RUN docker-php-ext-configure zip \
	&& docker-php-ext-install zip

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/

# Copying project and nginx, supervisor configuration
COPY . .
COPY ./nginx/php.conf /etc/nginx/conf.d/php.conf
COPY ./supervisor /etc/supervisor/conf.d

# Cron jobs
#RUN printf '* * * * * cd /var/www/ && /usr/local/bin/php artisan schedule:run >> /var/log/cron.log 2>&1\n' >> /root/crontab
#RUN printf '* * * * * rm -rf /tmp/.org.chromium.Chromium* >> /var/log/cron.log 2>&1\n#' >> /root/crontab
#RUN touch /var/log/cron.log
#RUN crontab /root/crontab

# Composer install command and php commands
RUN composer install
RUN php artisan migrate
RUN php artisan view:clear
RUN php artisan cache:clear

# Set memory limit unlimited for some tests and then delete that script (uncomment, if you need it)
#RUN echo "memory_limit = -1" > $PHP_INI_DIR/conf.d/memory-limit.ini
#RUN rm $PHP_INI_DIR/conf.d/memory-limit.ini

# Set right permissions commands
RUN gpasswd -a "root" www-data
RUN chown -R "root":www-data /var/www
RUN find /var/www -type f -exec chmod 0660 {} \;
RUN find /var/www -type d -exec chmod 2770 {} \;

# Run command
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
