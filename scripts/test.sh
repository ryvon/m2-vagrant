#!/usr/bin/env bash

. /vagrant/etc/env

[[ -z ${VAGRANT_ROOT} ]] && exit 1

SETUP_LOG="${VAGRANT_ROOT}/log/setup.log"

export SETUP_LOG

echo "Restarting services"
service mailhog restart
service mysql restart
service apache2 restart

# If running through bash in Windows we don't use the same hosts file that gets updated by hostmanager.  We use the IP
# specifying the Host header to get around that.
HOME_PAGE_CONTENT="$(curl --silent --show-error --location --max-time 20 --connect-timeout 20 --header "Host: ${VAGRANT_HOST}" --insecure "https://${VAGRANT_IP}/")"
if [[ ${HOME_PAGE_CONTENT} =~ ${MAGENTO_SEARCH_PATTERN} ]]; then
  echo "Site test successful"
else
  echo "Failed to load site"
fi

echo " - Frontend: ${MAGENTO_BASE_URL}"
echo " - Admin:    ${MAGENTO_ADMIN_URL}"
echo " - MailHog:  ${MAGENTO_BASE_URL}mailhog/"
