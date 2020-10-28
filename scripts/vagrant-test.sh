#!/usr/bin/env bash

export VAGRANT_ROOT='/vagrant'

# shellcheck source=./include/bootstrap.sh
. "${VAGRANT_ROOT}/scripts/include/bootstrap.sh" "$@" || exit 1

logGroup "Restarting services"

logInfo "Restarting elasticsearch"
runCommand service elasticsearch restart || exit 1

logInfo "Restarting mailhog"
runCommand service mailhog restart || exit 1

logInfo "Restarting apache2"
runCommand service apache2 restart || exit 1

logInfo "Restarting mysql"
runCommand service mysql restart || exit 1

check_host="${VAGRANT_HOSTNAME}"

# Use the IP with the hosts header if possible in case the host not resolvable by Vagrant.
if [[ -n "${VAGRANT_IP}" ]]; then
  check_host="${VAGRANT_IP}"
fi

logGroup "Checking services"

testUrl "MailHog: " "${check_host}" "mailhog" "MailHog" "${VAGRANT_HOSTNAME}"
testUrl "Frontend:" "${check_host}" "" "var BASE_URL = '" "${VAGRANT_HOSTNAME}"
testUrl "Admin:   " "${check_host}" "${MAGENTO_ADMIN_URI}" "Magento Commerce Inc." "${VAGRANT_HOSTNAME}"
