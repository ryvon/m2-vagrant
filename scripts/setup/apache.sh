#!/usr/bin/env bash
set -e

[[ -z ${SETUP_LOG} ]] && exit 1

echo "Installing apache2"
{
  apt-get -y install apache2
  service apache2 stop
  a2enmod ssl rewrite macro

  # Substitute is to add a base href in the mailhog source, headers is to ensure it is run
  a2enmod substitute headers

  # We proxy mailhog requests which requires both http and websocket proxies
  a2enmod proxy proxy_http proxy_wstunnel

  # shellcheck disable=SC2035
  a2dissite *

  CUSTOM_VHOST_CONFIG="${VAGRANT_ROOT}/etc/apache/vagrant_virtual_host.conf"
  DIST_VHOST_CONFIG="${VAGRANT_ROOT}/etc/apache/vagrant_virtual_host.conf.dist"
  if [[ -f ${CUSTOM_VHOST_CONFIG} ]]; then
    VHOST_CONFIG=${CUSTOM_VHOST_CONFIG}
  else
    VHOST_CONFIG=${DIST_VHOST_CONFIG}
  fi

  VHOST_CONFIG_LOCATION="/etc/apache2/sites-available/vagrant.conf"
  cp "${VHOST_CONFIG}" "${VHOST_CONFIG_LOCATION}"
  sed -i "s|\[VAGRANT_HOST\]|${VAGRANT_HOST}|g" "${VHOST_CONFIG_LOCATION}"
  sed -i "s|\[APACHE_ROOT\]|${APACHE_ROOT}|g" "${VHOST_CONFIG_LOCATION}"

  a2ensite vagrant.conf

  sed -i "s|APACHE_RUN_USER=www-data|APACHE_RUN_USER=vagrant|g" "/etc/apache2/envvars"
  sed -i "s|APACHE_RUN_GROUP=www-data|APACHE_RUN_GROUP=vagrant|g" "/etc/apache2/envvars"

  # This is to fix the "AH00144: couldn't grab the accept mutex" issue we were running into which was causing apache to
  # crash post-provisioning
  echo Mutex posixsem >/etc/apache2/conf-available/mutex.conf
  a2enconf mutex

  if [[ ! -d ${APACHE_ROOT} ]]; then
    mkdir "${APACHE_ROOT}"
  fi

  chown vagrant:vagrant "${APACHE_ROOT}"

  # Make sure the vagrant user can read the logs
  chmod 755 /var/log/apache2
  chmod 644 /var/log/apache2/*

  service apache2 start
} >>"${SETUP_LOG}"
