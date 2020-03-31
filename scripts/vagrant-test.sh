#!/usr/bin/env bash

export VAGRANT_ROOT='/vagrant'

# shellcheck source=./include/bootstrap.sh
. "${VAGRANT_ROOT}/scripts/include/bootstrap.sh" "$@" || exit 1

restartServices || exit 1

check_host="${VAGRANT_HOST}"

# Use the IP with the hosts header if possible in case the host not resolvable by Vagrant.
if [[ -n "${VAGRANT_IP}" ]]; then
  check_host="${VAGRANT_IP}"
fi

logGroup "Checking services"

testUrl "MailHog: " "${check_host}" "mailhog" "MailHog" "${VAGRANT_HOST}"
testUrl "Frontend:" "${check_host}" "" "var BASE_URL = '" "${VAGRANT_HOST}"
testUrl "Admin:   " "${check_host}" "${MAGENTO_ADMIN_URI}" "Magento Commerce Inc." "${VAGRANT_HOST}"

exit 0