FROM php:7.4.33-fpm

# install dependencies
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN apt-get update && apt-get install -y zip git openssh-client
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy the SSH key and set permissions
RUN mkdir -p -m 0700 /var/www/html/.ssh 
COPY ./.ssh/ /var/www/html/.ssh/
RUN chmod 700 /var/www/html/.ssh
RUN chmod 600 /var/www/html/.ssh/id_ed25519
RUN chmod 600 /var/www/html/.ssh/config
RUN chmod 600 /var/www/html/.ssh/known_hosts
RUN chown -R www-data:www-data /var/www/html/.ssh
RUN ssh-keyscan github.com >> /var/www/html/.ssh/known_hosts

ENV HOME=/var/www/html

# Git configuration
RUN git config --global core.sshCommand 'ssh -i /var/www/html/.ssh/id_ed25519'
RUN git config --global user.name "Jules Hemery"
RUN git config --global user.email "mrcouvbat@gmail.com"

# Install PHP extensions
RUN install-php-extensions zip pdo_mysql

RUN usermod -d /var/www/html www-data
USER www-data
WORKDIR /var/www/html