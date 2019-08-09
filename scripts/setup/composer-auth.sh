#!/usr/bin/env bash

[[ -z ${SETUP_LOG} ]] && exit 1

if [[ "${COMPOSER_AUTH_JSON}" == "" ]] || [[ "${COMPOSER_AUTH_HOME}" == "" ]]; then
  exit 1
fi

COMPOSER_AUTH_ROOT=$(dirname "${COMPOSER_AUTH_HOME}")

if [[ -f ${COMPOSER_AUTH_JSON} ]] && [[ ! -f ${COMPOSER_AUTH_HOME} ]]; then
  echo " - Installing composer auth config to ${COMPOSER_AUTH_HOME}" >&2

  if [[ ! -d "${COMPOSER_AUTH_ROOT}" ]]; then
    mkdir "${COMPOSER_AUTH_ROOT}"
  fi
  cp "${COMPOSER_AUTH_JSON}" "${COMPOSER_AUTH_HOME}"

  if [[ "${COMPOSER_CHOWN}" != "" ]]; then
    chown "${COMPOSER_CHOWN}":"${COMPOSER_CHOWN}" "${COMPOSER_AUTH_ROOT}"
    chown "${COMPOSER_CHOWN}":"${COMPOSER_CHOWN}" "${COMPOSER_AUTH_ROOT}/*"
  fi
fi
