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

logGroup "Checking services"

testUrl "MailHog: " "${MAGENTO_BASE_URL}mailhog" "MailHog"
testUrl "Frontend:" "${MAGENTO_BASE_URL}" "var BASE_URL = '"
testUrl "Admin:   " "${MAGENTO_BASE_URL}${MAGENTO_ADMIN_URI}" "Magento Commerce Inc."
