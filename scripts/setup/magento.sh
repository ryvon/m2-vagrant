#!/usr/bin/env bash
set -e

[[ -z ${SETUP_LOG} ]] && exit 1

echo "Installing Magento"
{
  CURRENT_MAGENTO_ARCHIVE="magento-${MAGENTO_REPO_VERSION}.tar"
  CURRENT_SAMPLE_DATA_ARCHIVE="sample-data-${MAGENTO_SAMPLE_DATA_VERSION}.tar"
  SAMPLE_DATA_ROOT="/home/vagrant/sample-data"

  rm -rf "${APACHE_ROOT}"
  mkdir "${APACHE_ROOT}"
  chown vagrant:vagrant "${APACHE_ROOT}"

  service apache2 restart

  echo " - Extracting Magneto to ${APACHE_ROOT}" >&2
  tar xf "${VAGRANT_ROOT}/archive/${CURRENT_MAGENTO_ARCHIVE}" --directory "${APACHE_ROOT}"
  if [[ $? -ne 0 ]]; then
    echo " - Failed to extract Magento" >&2
    exit 1
  fi

  rm -rf "${SAMPLE_DATA_ROOT}"
  mkdir "${SAMPLE_DATA_ROOT}"
  chown vagrant:vagrant "${SAMPLE_DATA_ROOT}"

  echo " - Extracting sample data to ${SAMPLE_DATA_ROOT}" >&2
  tar xf "${VAGRANT_ROOT}/archive/${CURRENT_SAMPLE_DATA_ARCHIVE}" --directory "${SAMPLE_DATA_ROOT}"
  if [[ $? -ne 0 ]]; then
    echo " - Failed to extract sample data" >&2
    exit 1
  fi

  su vagrant -c $'cp -R "${SAMPLE_DATA_ROOT}/app/" "${APACHE_ROOT}"'
  su vagrant -c $'cp -R "${SAMPLE_DATA_ROOT}/pub/" "${APACHE_ROOT}"'
  su vagrant -c $'cp -R "${SAMPLE_DATA_ROOT}/dev/" "${APACHE_ROOT}"'

  echo " - Clearing database" >&2
  mysql -u root <<EOSQL
DROP DATABASE ${MYSQL_DATABASE};
CREATE DATABASE ${MYSQL_DATABASE};
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO ${MYSQL_USER}@'localhost';
FLUSH PRIVILEGES;
EOSQL

  pushd "${APACHE_ROOT}" >/dev/null || {
    echo " - Failed to change directory" >&2
    exit 1
  }

  echo " - Running setup:install" >&2
  chmod u+x bin/magento
  su vagrant -c "bin/magento setup:install \
    --base-url=${MAGENTO_BASE_URL} \
    --db-host=localhost \
    --db-name=${MYSQL_DATABASE} \
    --db-user=${MYSQL_USER} \
    --db-password=${MYSQL_PASSWORD} \
    --backend-frontname=${MAGENTO_ADMIN_URI} \
    --admin-email=${MAGENTO_ADMIN_EMAIL} \
    --admin-user=${MAGENTO_ADMIN_USER} \
    --admin-password=${MAGENTO_ADMIN_PASSWORD} \
    --timezone=${MAGENTO_TIMEZONE} \
    --admin-firstname=Admin \
    --admin-lastname=Account \
    --language=en_US \
    --currency=USD \
    --use-rewrites=1"
  if [[ $? -ne 0 ]]; then
    echo " - Failed to setup Magento" >&2
    exit 1
  fi

  export COMPOSER_AUTH_JSON="${VAGRANT_ROOT}/etc/composer/auth.json"
  export COMPOSER_AUTH_HOME="${APACHE_ROOT}/var/composer_home/auth.json"

  # shellcheck source=./composer-auth.sh
  . "${VAGRANT_ROOT}/scripts/setup/composer-auth.sh"

  echo " - Enabling developer mode" >&2
  su vagrant -c "bin/magento deploy:mode:set developer"

  popd >/dev/null || {
    echo " - Failed to change directory" >&2
    exit 1
  }
} >>"${SETUP_LOG}"