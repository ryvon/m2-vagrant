#!/usr/bin/env bash

if [[ -z "${VAGRANT_ROOT}" ]]; then
  echo "VAGRANT_ROOT not defined"
  return 1
fi

if [[ ! -f "${VAGRANT_ROOT}/etc/env" ]]; then
  echo "Vagrant env file missing at \"${VAGRANT_ROOT}/etc/env\""
  return 1
fi

# shellcheck source=../../etc/env
. "${VAGRANT_ROOT}/etc/env"

export CONFIG_ROOT="${VAGRANT_ROOT}/etc"
export SCRIPTS_ROOT="${VAGRANT_ROOT}/scripts"
export LOG_ROOT="${VAGRANT_ROOT}/log"

export DEBIAN_FRONTEND=noninteractive # https://serverfault.com/a/670688

# shellcheck source=./helpers.sh
. "${SCRIPTS_ROOT}/include/helpers.sh" || return 1

# shellcheck source=./system.sh
. "${SCRIPTS_ROOT}/include/system.sh" || return 1

# shellcheck source=./magento.sh
. "${SCRIPTS_ROOT}/include/magento.sh" || return 1

# shellcheck source=./node.sh
. "${SCRIPTS_ROOT}/include/node.sh" || return 1

# shellcheck source=./apache.sh
. "${SCRIPTS_ROOT}/include/apache.sh" || return 1

# shellcheck source=./mysql.sh
. "${SCRIPTS_ROOT}/include/mysql.sh" || return 1

# shellcheck source=./php.sh
. "${SCRIPTS_ROOT}/include/php.sh" || return 1

# shellcheck source=./mailhog.sh
. "${SCRIPTS_ROOT}/include/mailhog.sh" || return 1

# shellcheck source=./composer.sh
. "${SCRIPTS_ROOT}/include/composer.sh" || return 1

# shellcheck source=./letsencrypt.sh
. "${SCRIPTS_ROOT}/include/letsencrypt.sh" || return 1
