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

  COMPOSER_AUTH_JSON="${VAGRANT_ROOT}/etc/composer/auth.json"
  COMPOSER_AUTH_HOME="${COMPOSER_HOME}/auth.json"

  if [[ -f ${COMPOSER_AUTH_JSON} ]] && [[ ! -f ${COMPOSER_AUTH_HOME} ]]; then
    echo " - Installing composer auth config to ${COMPOSER_AUTH_HOME}" >&2

    if [[ ! -d ${COMPOSER_HOME} ]]; then
      mkdir "${COMPOSER_HOME}"
      chown vagrant:vagrant "${COMPOSER_HOME}"
    fi
    cp "${COMPOSER_AUTH_JSON}" "${COMPOSER_AUTH_HOME}"
    chown vagrant:vagrant "${COMPOSER_HOME}/auth.json"
  fi
} >>"${SETUP_LOG}"
