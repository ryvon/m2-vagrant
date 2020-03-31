#!/usr/bin/env bash

getComposerVersion() {
  getAppVersion "composer" "--version" false 's/^.*version \([^ ]*\).*$/\1/' true
  return $?
}

installComposer() {
  local composer_binary="/usr/local/bin/composer"

  logGroup "Installing composer"

  local existing_version
  existing_version=$(getComposerVersion)
  if [[ -n "${existing_version}" ]]; then
    logInfo "composer already installed (${existing_version})"
    return 0
  fi

  local expected_signature
  local actual_signature
  expected_signature="$(wget -q -O - https://composer.github.io/installer.sig)"
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  actual_signature="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

  if [[ "${expected_signature}" != "${actual_signature}" ]]; then
    rm composer-setup.php
    logError "Invalid composer installer signature"
    return 1
  fi

  if ! runCommand php composer-setup.php; then
    rm composer-setup.php
    logError "Invalid composer installer signature"
    return 1
  fi

  rm composer-setup.php
  runCommand mv composer.phar "${composer_binary}" || return 1
  runCommand chmod +x "${composer_binary}" || return 1
}

installComposerAuth() {
  local auth_file_source=$1
  local auth_file_target=$2
  local auth_target_chown_user=$3

  logGroup "Installing composer auth.json to \"$(dirname "${auth_file_target}")\""

  if [[ ! -f "${auth_file_source}" ]]; then
    logError "Source file does not exist"
    return 1
  fi

  local auth_file_target_path
  auth_file_target_path=$(dirname "${auth_file_target}")

  if [[ ! -d "${auth_file_target_path}" ]]; then
    runCommand mkdir -p "${auth_file_target_path}" || return 1
  fi

  runCommand cp "${auth_file_source}" "${auth_file_target}" || return 1
  runCommand chmod 700 "${auth_file_target}" || return 1

  if [[ -n "${auth_target_chown_user}" ]]; then
    runCommand chown "${auth_target_chown_user}":"${auth_target_chown_user}" "${auth_file_target_path}" || return 1
    runCommand chown "${auth_target_chown_user}":"${auth_target_chown_user}" "${auth_file_target_path}/"* || return 1
  fi
}
