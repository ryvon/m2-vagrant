#!/usr/bin/env bash

getApacheVersion() {
  getAppVersion "apachectl" "-v" '^Server version' 's/^.*Apache\/\([^ ]*\).*$/\1/'
  return $?
}

installApache() {
  logGroup "Installing apache2"

  local existing_version
  existing_version=$(getApacheVersion)
  if [[ -n "${existing_version}" ]]; then
    logInfo "apache2 already installed (${existing_version})"
    return 0
  fi

  runCommand apt-get -y install apache2 || return 1
  runCommand a2enmod ssl rewrite macro || return 1

  # Enable the default SSL site
  runCommand a2ensite default-ssl || return 1

  # Substitute is to add a base href in the mailhog source, headers is to ensure it is run
  runCommand a2enmod substitute headers || return 1

  # We proxy mailhog requests which requires both http and websocket proxies
  runCommand a2enmod proxy proxy_http proxy_wstunnel || return 1

  # Add a macro directory and include it in the Apache config
  runCommand mkdir "/etc/apache2/macro" || return 1
  echo "IncludeOptional macro/*.macro" >/etc/apache2/conf-available/load-macros.conf
  runCommand a2enconf load-macros || return 1

  # Make sure we are running as the vagrant user instead of www-data
  runCommand sed --follow-symlinks -i "s|APACHE_RUN_USER=www-data|APACHE_RUN_USER=vagrant|g" "/etc/apache2/envvars" || return 1
  runCommand sed --follow-symlinks -i "s|APACHE_RUN_GROUP=www-data|APACHE_RUN_GROUP=vagrant|g" "/etc/apache2/envvars" || return 1

  # This is to fix the "AH00144: couldn't grab the accept mutex" issue we were running into which was causing apache to
  # crash post-provisioning
  echo Mutex posixsem >/etc/apache2/conf-available/mutex.conf
  runCommand a2enconf mutex || return 1

  # Make sure the vagrant user can read the logs
  runCommand chmod 755 /var/log/apache2 || return 1
  runCommand chmod 644 /var/log/apache2/* || return 1

  runCommand service apache2 restart || return 1
}
