#!/usr/bin/env bash

source /vagrant/etc/env

[[ -z ${VAGRANT_ROOT} ]] && exit 1

SETUP_LOG="${VAGRANT_ROOT}/log/setup"
export SETUP_LOG
export DEBIAN_FRONTEND=noninteractive # https://serverfault.com/a/670688

echo "Started $(date)" >"${SETUP_LOG}"

# shellcheck source=scripts/setup/update.sh
. "${VAGRANT_ROOT}/scripts/setup/update.sh"

# shellcheck source=scripts/setup/system-tools.sh
. "${VAGRANT_ROOT}/scripts/setup/system-tools.sh"

echo "Finished $(date)" >>"${SETUP_LOG}"
