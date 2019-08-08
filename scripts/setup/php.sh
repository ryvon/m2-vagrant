#!/usr/bin/env bash
set -e

[[ -z ${SETUP_LOG} ]] && exit 1

echo "Installing php7.1"
{
  curl -ssL -o /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
  sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'

  apt-get update
  apt-get -y install php7.1 php7.1-curl php7.1-bcmath php7.1-mbstring \
    php7.1-soap php7.1-xsl php7.1-mcrypt php7.1-zip \
    php7.1-mysql php7.1-intl php7.1-cli php7.1-json \
    php7.1-gd php7.1-opcache php7.1-xml

  echo "session.gc_maxlifetime = 86400" >/etc/php/7.1/mods-available/session_lifetime.ini
  phpenmod session_lifetime

  service apache2 restart
} >"${SETUP_LOG}-php"
