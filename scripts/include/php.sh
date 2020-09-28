#!/usr/bin/env bash

getPhpVersion() {
  getAppVersion "php" "--version" '^PHP' 's|.*PHP \([^ ]*\).*$|\1|'
  return $?
}

installPhp() {
  local php_version=$1

  if [[ -z "${php_version}" ]]; then
    logError "No php version specified to install"
    return 1
  fi

  logGroup "Installing php-${php_version}"

  local existing_version
  existing_version=$(getPhpVersion)
  if [[ -n "${existing_version}" ]]; then
    logInfo "php already installed (${existing_version})"
    return 0
  fi

  runCommand curl -ssL -o /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg || return 1
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" >/etc/apt/sources.list.d/php.list

  runCommand apt-get update || return 1

  # We can't use runCommand due to the 'Extracting templates from packages: X%' stderr output
  logDebug "Running command 'apt-get -y install \"php${php_version}\" ...'"
  local apt_output
  apt_output=$(apt-get -y install "php${php_version}" \
    "php${php_version}-bcmath" \
    "php${php_version}-cli" \
    "php${php_version}-curl" \
    "php${php_version}-gd" \
    "php${php_version}-intl" \
    "php${php_version}-json" \
    "php${php_version}-mbstring" \
    "php${php_version}-mysql" \
    "php${php_version}-opcache" \
    "php${php_version}-soap" \
    "php${php_version}-xml" \
    "php${php_version}-xsl" \
    "php${php_version}-zip" 2>&1)
  local apt_return=$?
  logDebug "Output: ${apt_output}"
  if [[ ${apt_return} -ne 0 ]]; then
    return 1
  fi

  if ! versionGTE "${php_version}" "7.2"; then
      apt_output=$(apt-get -y install "php${php_version}-mcrypt" 2>&1)
      apt_return=$?
      logDebug "Output: ${apt_output}"
      if [[ ${apt_return} -ne 0 ]]; then
        return 1
      fi
  fi

  echo "session.gc_maxlifetime = 86400" >"/etc/php/${php_version}/mods-available/session_lifetime.ini"
  runCommand phpenmod session_lifetime || return 1

  runCommand service apache2 restart || return 1
}
