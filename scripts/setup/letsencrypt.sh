#!/usr/bin/env bash
set -e

[[ -z ${SETUP_LOG} ]] && exit 1

[[ "${APACHE_USE_LETSENCRYPT}" == true ]] || exit 0

echo "Installing certbot for LetsEncrypt"
{
  echo deb http://deb.debian.org/debian stretch-backports main | tee -a /etc/apt/sources.list.d/backports.list
  apt-get update
  apt-get -y install certbot python-certbot-apache -t stretch-backports

  echo " - Requesting certificate" >&2
  if ! certbot --apache --agree-tos --register-unsafely-without-email --no-redirect -d "${VAGRANT_HOST}"; then
    echo " - Certificate request failed" >&2
    exit 0
  fi
  service apache2 restart
} >>"${SETUP_LOG}"
