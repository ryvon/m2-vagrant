#!/usr/bin/env bash
set -e

. /vagrant/etc/env

[[ -z ${VAGRANT_ROOT} ]] && exit 1

SETUP_LOG="${VAGRANT_ROOT}/log/setup.log"

export SETUP_LOG

echo "Restarting services"
service mailhog restart
service mysql restart
service apache2 restart

if [[ -z "${MAGENTO_ARCHIVE}" ]]; then
  exit 0
fi

echo " - Frontend: ${MAGENTO_BASE_URL}"
echo " - Admin:    ${MAGENTO_ADMIN_URL}"
echo " - MailHog:  ${MAGENTO_BASE_URL}mailhog/"

echo "Checking site status"

# If running through bash in Windows we don't use the same hosts file that gets updated by hostmanager.  We use the IP
# specifying the Host header to get around that.
CHECK_HOST="${VAGRANT_HOST}"
if [[ -n "${VAGRANT_IP}" ]]; then
  CHECK_HOST="${VAGRANT_IP}"
fi
HOME_PAGE_CONTENT="$(curl --silent --show-error --location --max-time 20 --connect-timeout 20 --header "Host: ${VAGRANT_HOST}" --insecure "https://${CHECK_HOST}/")"
if [[ ${HOME_PAGE_CONTENT} =~ ${MAGENTO_SEARCH_PATTERN} ]]; then
  echo " - Magento found"
else
  echo " - Failed to load site"
fi
