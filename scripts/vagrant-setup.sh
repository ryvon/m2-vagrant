#!/usr/bin/env bash

export VAGRANT_ROOT='/vagrant'

# shellcheck source=./include/bootstrap.sh
. "${VAGRANT_ROOT}/scripts/include/bootstrap.sh" "$@" || exit 1

logDebug "vagrant-setup.sh started"

updateSystem || exit 1
installSystemTools || exit 1
installSwapFile "/var/swap.1" "1G" || exit 1
installApache || exit 1
installMysql || exit 1
installPhp "${PHP_VERSION}" || exit 1
installMailhog "${VAGRANT_ROOT}/etc/mailhog" "${PHP_VERSION}" || exit 1
installComposer || exit 1
installNodeJs "10" || exit 1
installGruntCli || exit 1
installGulp || exit 1

vagrant_ssh_key_file="${VAGRANT_ROOT}/etc/ssh/${VAGRANT_SSH_KEY}"
if [[ -f "${vagrant_ssh_key_file}" ]]; then
  installSshKey "/home/vagrant/.ssh" "${vagrant_ssh_key_file}" || exit 1
fi

composer_auth_file="${VAGRANT_ROOT}/etc/composer/auth.json"
if [[ -f "${composer_auth_file}" ]]; then
  installComposerAuth "${composer_auth_file}" "/home/vagrant/.composer/auth.json" "vagrant" || exit 1
fi

if [[ -n "${MAGENTO_ARCHIVE}" ]] && [[ ! -f "${VAGRANT_ROOT}/${MAGENTO_ARCHIVE}" ]]; then
  downloadMagento "${MAGENTO_REPO_NAME}" "${MAGENTO_REPO_URL}" "${MAGENTO_REPO_VERSION}" "${VAGRANT_ROOT}/${MAGENTO_ARCHIVE}" || exit 1
fi

if [[ -n "${MAGENTO_SAMPLE_DATA_ARCHIVE}" ]] && [[ ! -f "${VAGRANT_ROOT}/${MAGENTO_SAMPLE_DATA_ARCHIVE}" ]]; then
  downloadSampleData "${MAGENTO_SAMPLE_DATA_VERSION}" "${VAGRANT_ROOT}/${MAGENTO_SAMPLE_DATA_ARCHIVE}" || exit 1
fi

if [[ -n "${MAGENTO_ARCHIVE}" ]]; then
  configureMysqlForMagento "${MYSQL_DATABASE}" "${MYSQL_USER}" "${MYSQL_PASSWORD}" || exit 1
  configureApacheForMagento "${VAGRANT_ROOT}/etc/apache" "${VAGRANT_HOSTNAME}" "${APACHE_DOCUMENT_ROOT}" || exit 1

  prepareForMagentoInstall || exit 1

  installMagentoFiles "${VAGRANT_ROOT}/${MAGENTO_ARCHIVE}" "${MAGENTO_DOCUMENT_ROOT}" || exit 1

  if [[ -n "${MAGENTO_SAMPLE_DATA_ARCHIVE}" ]]; then
    installMagentoSampleData "${VAGRANT_ROOT}/${MAGENTO_SAMPLE_DATA_ARCHIVE}" "${MAGENTO_DOCUMENT_ROOT}" || exit 1
  fi

  setupMagentoDatabaseDefault "${MAGENTO_DOCUMENT_ROOT}" "https://${VAGRANT_HOSTNAME}/" "${MAGENTO_ADMIN_URI}" \
    "${MAGENTO_ADMIN_EMAIL}" "${MAGENTO_ADMIN_USER}" "${MAGENTO_ADMIN_PASSWORD}" "${MAGENTO_TIMEZONE}" \
    "${MYSQL_DATABASE}" "${MYSQL_USER}" "${MYSQL_PASSWORD}" || exit 1

  configureMagento "${MAGENTO_DOCUMENT_ROOT}" "https://${VAGRANT_HOSTNAME}/" "${MAGENTO_ADMIN_URI}" || exit 1

  finishMagentoInstall "${MAGENTO_DOCUMENT_ROOT}" || exit 1
fi

if [[ "${APACHE_USE_LETSENCRYPT}" == true ]]; then
  installLetsEncrypt "${VAGRANT_HOSTNAME}" || exit 1
fi

logDebug "vagrant-setup.sh finished"
