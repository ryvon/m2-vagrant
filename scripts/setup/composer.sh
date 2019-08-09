#!/usr/bin/env bash

[[ -z ${SETUP_LOG} ]] && exit 1

echo "Installing composer"
{
  if [[ ! -x ${COMPOSER_BIN} ]]; then
    echo " - Installing composer to ${COMPOSER_BIN}" >&2

    EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [[ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]]; then
      rm -f composer-setup.php
      echo " - Invalid composer installer signature" >&2
      exit 1
    fi

    php composer-setup.php --quiet
    RESULT=$?

    rm -f composer-setup.php

    if [[ ! ${RESULT} -eq 0 ]]; then
      echo " - Failed to install" >&2
      exit 1
    fi

    mv composer.phar "${COMPOSER_BIN}"
    chmod +x "${COMPOSER_BIN}"
  fi

  export COMPOSER_AUTH_JSON="${VAGRANT_ROOT}/etc/composer/auth.json"
  export COMPOSER_AUTH_HOME="${COMPOSER_HOME}/auth.json"

  # shellcheck source=./composer-auth.sh
  . "${VAGRANT_ROOT}/scripts/setup/composer-auth.sh"
} >>"${SETUP_LOG}"
