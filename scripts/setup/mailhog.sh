#!/usr/bin/env bash
set -e

[[ -z ${SETUP_LOG} ]] && exit 1

echo "Installing mailhog"
{
  MAILHOG_URL="https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_linux_amd64"
  MAILHOG_BINARY="/usr/local/bin/mailhog"

  MAILHOG_SENDMAIL_URL="https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64"
  MAILHOG_SENDMAIL_BINARY="/usr/local/bin/mhsendmail"

  curl --silent --show-error --location --output ${MAILHOG_BINARY} ${MAILHOG_URL}
  curl --silent --show-error --location --output ${MAILHOG_SENDMAIL_BINARY} ${MAILHOG_SENDMAIL_URL}

  chown root:root ${MAILHOG_BINARY} ${MAILHOG_SENDMAIL_BINARY}
  chmod 755 ${MAILHOG_BINARY} ${MAILHOG_SENDMAIL_BINARY}

  cp "${VAGRANT_ROOT}/etc/mailhog/init.d.sh" "/etc/init.d/mailhog"
  cp "${VAGRANT_ROOT}/etc/mailhog/mailhog.service" "/etc/systemd/system/mailhog.service"
  sed -i "s|\[MAILHOG_BINARY\]|${MAILHOG_BINARY}|g" "/etc/init.d/mailhog"
  sed -i "s|\[MAILHOG_BINARY\]|${MAILHOG_BINARY}|g" "/etc/systemd/system/mailhog.service"

  chown root:root /etc/init.d/mailhog /etc/systemd/system/mailhog.service
  chmod 755 /etc/init.d/mailhog /etc/systemd/system/mailhog.service

  echo "sendmail_path = ${MAILHOG_SENDMAIL_BINARY}" >/etc/php/7.1/mods-available/mailhog.ini
  phpenmod mailhog

  service mailhog start
  service apache2 restart
} >>"${SETUP_LOG}"
