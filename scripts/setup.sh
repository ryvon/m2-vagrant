#!/usr/bin/env bash
set -e

. /vagrant/etc/env

[[ -z ${VAGRANT_ROOT} ]] && exit 1

SETUP_LOG="${VAGRANT_ROOT}/log/setup.log"

export SETUP_LOG
export DEBIAN_FRONTEND=noninteractive # https://serverfault.com/a/670688
export COMPOSER_CHOWN=vagrant

if [[ -f ${SETUP_LOG} ]]; then
  rm "${SETUP_LOG}"
fi

# shellcheck source=./setup/update.sh
. "${VAGRANT_ROOT}/scripts/setup/update.sh"

# shellcheck source=./setup/swap.sh
. "${VAGRANT_ROOT}/scripts/setup/swap.sh"

# shellcheck source=./setup/system-tools.sh
. "${VAGRANT_ROOT}/scripts/setup/system-tools.sh"

# shellcheck source=./setup/apache.sh
. "${VAGRANT_ROOT}/scripts/setup/apache.sh"

# shellcheck source=./setup/mysql.sh
. "${VAGRANT_ROOT}/scripts/setup/mysql.sh"

# shellcheck source=./setup/php.sh
. "${VAGRANT_ROOT}/scripts/setup/php.sh"

# shellcheck source=./setup/mailhog.sh
. "${VAGRANT_ROOT}/scripts/setup/mailhog.sh"

# shellcheck source=./setup/composer.sh
. "${VAGRANT_ROOT}/scripts/setup/composer.sh"

# shellcheck source=./setup/magento.sh
. "${VAGRANT_ROOT}/scripts/setup/magento.sh"
