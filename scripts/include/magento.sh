#!/usr/bin/env bash

configureMysqlForMagento() {
  local mysql_database=$1
  local mysql_user=$2
  local mysql_password=$3

  logGroup "Configuring mysql-server for Magento"

  if [[ -z "$(getMysqlVersion)" ]]; then
    logError "mysql-server not found to configure"
    return 0
  fi

  if [[ ! -f "/etc/mysql/conf.d/magento.cnf" ]]; then
    logInfo "Increasing innodb_buffer_pool_size"
    echo "[mysqld]" >/etc/mysql/conf.d/magento.cnf
    echo "innodb_buffer_pool_size=1G" >>/etc/mysql/conf.d/magento.cnf

    logInfo "Restarting MySQL"
    runCommand service mysql restart || return 1
  fi

  if grep -q "${mysql_database}" <<<"$(mysql -u "${mysql_user}" -p"${mysql_password}" -sse "show databases;" 2>/dev/null)"; then
    logInfo "mysql-server already configured"
    return 0
  fi

  logInfo "Creating user \"${mysql_user}\""
  runCommand mysql -u root -e "CREATE USER IF NOT EXISTS '${mysql_user}'@'localhost' IDENTIFIED BY '${mysql_password}';" || return 1
  runCommand mysql -u root -e "CREATE USER IF NOT EXISTS '${mysql_user}'@'%' IDENTIFIED BY '${mysql_password}';" || return 1

  logInfo "Creating database \"${mysql_database}\""
  runCommand mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${mysql_database};" || return 1

  logInfo "Granting privileges"
  runCommand mysql -u root -e "GRANT ALL PRIVILEGES ON ${mysql_database}.* TO ${mysql_user}@'localhost';" || return 1
  runCommand mysql -u root -e "GRANT ALL PRIVILEGES ON ${mysql_database}.* TO ${mysql_user}@'%';" || return 1
  runCommand mysql -u root -e "FLUSH PRIVILEGES;" || return 1
}

configureApacheForMagento() {
  local config_path=$1
  local vagrant_host=$2
  local document_root=$3

  logGroup "Configuring apache2 for Magento"

  if [[ -z "$(getApacheVersion)" ]]; then
    logError "apache2 not found to configure"
    return 1
  fi

  local vhost_config_location="/etc/apache2/sites-available/vagrant.conf"
  local vhost_activated_location="${vhost_config_location/available/enabled}"
  if [[ -f "${vhost_activated_location}" ]]; then
    logInfo "apache2 already configured"
    return 0
  fi

  logInfo "Disabling sites"
  # Disable any enabled sites
  find /etc/apache2/sites-enabled/ -type l | while read -r enabled_site; do
    runCommand /usr/sbin/a2dissite "$(basename "${enabled_site}")" || return 1
  done

  logInfo "Installing new site"
  # Find the virtual host file we want to copy
  local custom_vhost_config="${config_path}/vagrant_virtual_host.conf"
  local dist_custom_vhost_config="${config_path}/vagrant_virtual_host.conf.dist"
  local vhost_config
  if [[ -f ${custom_vhost_config} ]]; then
    vhost_config=${custom_vhost_config}
  else
    vhost_config=${dist_custom_vhost_config}
  fi

  # Copy the virtual host file and replace the paths in it
  runCommand cp "${vhost_config}" "${vhost_config_location}" || return 1
  runCommand sed --follow-symlinks -i "s|\[VAGRANT_HOST\]|${vagrant_host}|g" "${vhost_config_location}" || return 1
  runCommand sed --follow-symlinks -i "s|\[APACHE_DOCUMENT_ROOT\]|${document_root}|g" "${vhost_config_location}" || return 1

  # Setup the document root
  if [[ ! -d "${document_root}" ]]; then
    runCommand mkdir -p "${document_root}" || return 1
  fi
  runCommand chown vagrant:vagrant -R "${document_root}" || return 1

  logInfo "Enabling new site"
  # Enable the new site
  runCommand a2ensite vagrant.conf || return 1

  logInfo "Restarting apache2"
  runCommand service apache2 start || return 1
}

prepareForMagentoInstall() {
  logGroup "Preparing for Magento install"

  logInfo "Stopping apache2"
  runCommand service apache2 stop || return 1

  if [[ -n "$(crontab -u vagrant -l 2>/dev/null)" ]]; then
    logInfo "Clearing crontab"
    runCommand crontab -u vagrant -r || return 1
  fi
}

finishMagentoInstall() {
  local magento_install_path=$1

  logGroup "Finalizing Magento install"

  logInfo "Starting apache2"
  runCommand service apache2 start || return 1

  logInfo "Installing cron"
  local magento_bin="${magento_install_path}/bin/magento"
  runCommand su vagrant -c "${magento_bin} cron:install" || return 1
}

installMagentoFiles() {
  local magento_install_archive=$1
  local magento_install_path=$2

  logGroup "Installing Magento files from \"${magento_install_archive}\" to \"${magento_install_path}\""

  if [[ ! -f "${magento_install_archive}" ]]; then
    logError "Magento archive not found"
    return 1
  fi

  logInfo "Clearing installation path"
  runCommand rm -rf "${magento_install_path}" || return 1
  runCommand mkdir -p "${magento_install_path}" || return 1
  runCommand chown vagrant:vagrant "${magento_install_path}" || return 1

  logInfo "Extracting Magento archive"
  runCommand tar xf "${magento_install_archive}" --directory "${magento_install_path}" || return 1

  local magento_bin="${magento_install_path}/bin/magento"
  runCommand chmod u+x "${magento_bin}" || return 1
}

installMagentoSampleData() {
  local sample_data_archive=$1
  local magento_install_path=$2

  logGroup "Installing sample data files from \"${sample_data_archive}\""

  if [[ ! -f "${sample_data_archive}" ]]; then
    logError "sample data archive not found"
    return 1
  fi

  local sample_data_temp="/home/vagrant/magento-sample-data"

  if [[ -d "${sample_data_temp}" ]]; then
    logInfo "Cleaning up old sample data directory"
    runCommand rm -rf "${sample_data_temp}" || return 1
  fi

  runCommand mkdir "${sample_data_temp}" || return 1
  runCommand chown vagrant:vagrant "${sample_data_temp}" || return 1

  logInfo "Extracting sample data temporary location"
  runCommand tar xf "${sample_data_archive}" --directory "${sample_data_temp}" || return 1

  logInfo "Copying sample data to \"${magento_install_path}\""
  runCommand su vagrant -c "cp -R '${sample_data_temp}/app/' '${sample_data_temp}/dev/' '${sample_data_temp}/pub/' '${magento_install_path}'" || return 1
  runCommand rm -rf "${sample_data_temp}" || return 1
}

setupMagentoDatabaseDefault() {
  local magento_install_path=$1
  local magento_base_url=$2
  local magento_admin_uri=$3
  local magento_admin_email=$4
  local magento_admin_user=$5
  local magento_admin_password=$6
  local magento_timezone=$7
  local mysql_database=$8
  local mysql_user=$9
  local mysql_password=${10}

  logGroup "Creating Magento database"

  logInfo "Emptying current database"
  runCommand mysql -u root -e "DROP DATABASE ${mysql_database};" || return 1
  runCommand mysql -u root -e "CREATE DATABASE ${mysql_database};" || return 1
  runCommand mysql -u root -e "GRANT ALL PRIVILEGES ON ${mysql_database}.* TO ${mysql_user}@'localhost';" || return 1
  runCommand mysql -u root -e "GRANT ALL PRIVILEGES ON ${mysql_database}.* TO ${mysql_user}@'%';" || return 1
  runCommand mysql -u root -e "FLUSH PRIVILEGES;" || return 1

  logInfo "Running setup:install"
  local magento_bin="${magento_install_path}/bin/magento"
  runCommand su vagrant -c "${magento_bin} setup:install \
      --base-url=${magento_base_url} \
      --db-host=localhost \
      --db-name=${mysql_database} \
      --db-user=${mysql_user} \
      --db-password=${mysql_password} \
      --backend-frontname=${magento_admin_uri} \
      --admin-email=${magento_admin_email} \
      --admin-user=${magento_admin_user} \
      --admin-password=${magento_admin_password} \
      --timezone=${magento_timezone} \
      --admin-firstname=Admin \
      --admin-lastname=Account \
      --language=en_US \
      --currency=USD \
      --use-rewrites=1" || return 1
}

configureMagento() {
  local magento_install_path=$1
  local magento_base_url=$2

  local magento_bin="${magento_install_path}/bin/magento"

  logGroup "Configuring Magento"

  logInfo "Setting developer mode"
  runCommand su vagrant -c "${magento_bin} deploy:mode:set developer" || return 1

  logInfo "Setting base URLs"
  runCommand su vagrant -c "${magento_bin} config:set web/unsecure/base_url '${magento_base_url}'" || return 1
  runCommand su vagrant -c "${magento_bin} config:set web/secure/base_url '${magento_base_url}'" || return 1

  logInfo "Disabling Recaptcha"
  runCommand su vagrant -c "${magento_bin} msp:security:recaptcha:disable" || return 1

  logInfo "Enabling cache"
  runCommand su vagrant -c "${magento_bin} cache:enable" || return 1
  runCommand su vagrant -c "${magento_bin} cache:flush" || return 1
}