#!/usr/bin/env bash
set -e

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

. /vagrant/etc/env

[[ -z ${VAGRANT_ROOT} ]] && exit 1

SETUP_LOG="${VAGRANT_ROOT}/log/setup.log"

export SETUP_LOG
export DEBIAN_FRONTEND=noninteractive # https://serverfault.com/a/670688
export COMPOSER_CHOWN=vagrant

if [[ -f ${SETUP_LOG} ]]; then
  rm "${SETUP_LOG}"
fi

# shellcheck source=./setup/magento.sh
. "${VAGRANT_ROOT}/scripts/setup/magento.sh"