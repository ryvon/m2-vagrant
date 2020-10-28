#!/usr/bin/env bash

getMailhogVersion() {
  getAppVersion "mailhog" "--version" false 's/^.*version: \([^ ]*\)$/\1/'
  return $?
}

configureApacheForMailhog() {
  local config_path=$1

  # Add the Mailhog Apache macro
  runCommand cp "${config_path}/apache-proxy.macro" "/etc/apache2/macro/mailhog.macro" || return 1

  # Use the macro in any enabled sites
  find /etc/apache2/sites-enabled/ -type l | while read -r enabled_site; do
    if ! grep -q "VHostProxyMailhog" "${enabled_site}"; then
      runCommand sed --follow-symlinks -i "s|DocumentRoot \\(.*\\)|DocumentRoot \\1\\n\    Use VHostProxyMailhog|" "${enabled_site}" || return 1
    fi
  done
}

installMailhog() {
  local config_path=$1
  local php_version=$2

  local main_url="https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_linux_amd64"
  local main_binary="/usr/local/bin/mailhog"

  local sendmail_url="https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64"
  local sendmail_binary="/usr/local/bin/mhsendmail"

  logGroup "Installing mailhog"

  local existing_version
  existing_version=$(getMailhogVersion)
  if [[ -n "${existing_version}" ]]; then
    logInfo "mailhog already installed (${existing_version})"
    return 0
  fi

  runCommand curl --silent --show-error --location --output ${main_binary} ${main_url} || return 1
  runCommand curl --silent --show-error --location --output ${sendmail_binary} ${sendmail_url} || return 1

  runCommand chown root:root ${main_binary} ${sendmail_binary} || return 1
  runCommand chmod 755 ${main_binary} ${sendmail_binary} || return 1

  runCommand cp "${config_path}/init.d.sh" "/etc/init.d/mailhog" || return 1
  runCommand cp "${config_path}/mailhog.service" "/etc/systemd/system/mailhog.service" || return 1
  runCommand sed --follow-symlinks -i "s|\[MAILHOG_BINARY\]|${main_binary}|g" "/etc/init.d/mailhog" || return 1
  runCommand sed --follow-symlinks -i "s|\[MAILHOG_BINARY\]|${main_binary}|g" "/etc/systemd/system/mailhog.service" || return 1

  runCommand chown root:root /etc/init.d/mailhog /etc/systemd/system/mailhog.service || return 1
  runCommand chmod 755 /etc/init.d/mailhog /etc/systemd/system/mailhog.service || return 1

  echo "sendmail_path = ${sendmail_binary}" >"/etc/php/${php_version}/mods-available/mailhog.ini"
  runCommand phpenmod mailhog || return 1

  configureApacheForMailhog "${config_path}" || return 1

  runCommand service mailhog start || return 1
  runCommand service apache2 restart || return 1
}
