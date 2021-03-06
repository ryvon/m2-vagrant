#!/usr/bin/env bash

getCertbotVersion() {
  getAppVersion "certbot" "--version" false 's/^.*certbot \([^ ]*\).*$/\1/'
  return $?
}

installLetsEncrypt() {
  local vagrant_hostname=$1

  logGroup "Installing certbot"

  local existing_version
  existing_version=$(getCertbotVersion)
  if [[ -n "${existing_version}" ]]; then
    logInfo "certbot already installed (${existing_version})"
  else
    local backports_line="deb http://deb.debian.org/debian stretch-backports main"
    local backports_file="/etc/apt/sources.list.d/backports.list"
    if [[ ! -f "${backports_file}" ]] || ! grep -q "${backports_line}" "${backports_file}"; then
      echo "${backports_line}" | tee -a "${backports_file}" >/dev/null
    fi
    runCommand apt-get update || return 1
    runCommand apt-get -y install certbot python-certbot-apache -t stretch-backports || return 1
  fi

  logGroup "Requesting certificate from LetsEncrypt"
  if [[ -d "/etc/letsencrypt/live/${vagrant_hostname}/" ]]; then
    logInfo "Certificate already exists"
  else
    local certbot_output
    certbot_output=$(certbot --apache --agree-tos --register-unsafely-without-email --no-redirect -d "${vagrant_hostname}" 2>&1)
    local certbot_return=$?
    logDebug "Certbot output: ${certbot_output}"
    if [[ ${certbot_return} -ne 0 ]]; then
      logError "Certificate generation failed, check log"
      return 1
    fi
    runCommand service apache2 restart || return 1
  fi
}
