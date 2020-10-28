#!/usr/bin/env bash

getJreVersion() {
  getAppVersion "java" "-version" " version " 's/.* version "\([^")]*\)"/\1/'
  return $?
}

installJre() {
  logGroup "Installing jre-headless"

  local existing_version
  existing_version=$(getJreVersion)
  if [[ -n "${existing_version}" ]]; then
    logInfo "jre-headless already installed (${existing_version})"
    return 0
  fi

  runCommand apt-get -y install default-jre-headless || return 1
}

installSelenium() {
  logGroup "Installing selenium-server-standalone"

  local install_target="/home/vagrant/selenium-server-standalone-3.141.59.jar"

  if [[ -f "${install_target}" ]]; then
    logInfo "selenium-server-standalone already installed"
    return 0
  fi

  runCommand curl -ssL -o /home/vagrant/selenium-server-standalone-3.141.59.jar \
    https://selenium-release.storage.googleapis.com/3.141/selenium-server-standalone-3.141.59.jar || return 1
  runCommand chown vagrant:vagrant /home/vagrant/selenium-server-standalone-*.jar || return 1
  runCommand apt-get -y install xvfb screen || return 1
}

stopSelenium() {
  runCommand su vagrant -c "screen -S selenium -p 0 -X quit >/dev/null" || return 1
}

startSelenium() {
  local current_session
  current_session=$(screen -ls | grep selenium)

  if [[ -n "${current_session}" ]]; then
    stopSelenium || return 1
  fi

  runCommand su vagrant -c "screen -d -m -S selenium xvfb-run --auto-servernum java \
    -Dwebdriver.chrome.driver=/home/vagrant/chromedriver \
    -jar /home/vagrant/selenium-server-standalone-3.141.59.jar" || return 1
}

getChromeVersion() {
  getAppVersion "google-chrome" "--version" false 's/^Google Chrome \([^ ]*\)/\1/'
  return $?
}

installChrome() {
  logGroup "Installing google-chrome"

  local existing_version
  existing_version=$(getChromeVersion)
  if [[ -n "${existing_version}" ]]; then
    logInfo "google-chrome already installed (${existing_version})"
    return 0
  fi

  runCommand wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb || return 1
  runCommand apt-get install -y ./google-chrome-stable_current_amd64.deb || return 1
  runCommand rm google-chrome-stable_current_amd64.deb || return 1
}

getChromeDriverVersion() {
  getAppVersion "/home/vagrant/chromedriver" "--version" false 's/^ChromeDriver \([^ ]*\)/\1/'
  return $?
}

installChromeDriver() {
  logGroup "Installing chromedriver"

  local existing_version
  existing_version=$(getChromeDriverVersion)
  if [[ -n "${existing_version}" ]]; then
    logInfo "chromedriver already installed (${existing_version})"
    return 0
  fi

  pushd /home/vagrant >/dev/null || return 1
  runCommand curl -ssL -o chromedriver_linux64.zip \
    https://chromedriver.storage.googleapis.com/86.0.4240.22/chromedriver_linux64.zip || return 1
  runCommand unzip chromedriver_linux64.zip || return 1
  runCommand rm chromedriver_linux64.zip || return 1
  runCommand chown vagrant:vagrant /home/vagrant/chromedriver || return 1
  popd >/dev/null || return 1
}

configureMftf() {
  local magento_install_path=$1
  local magento_base_url=$2
  local magento_admin_uri=$3
  local magento_admin_username=$4
  local magento_admin_password=$5
  local magento_version=$6
  local magento_otp_shared_secret=$7

  local magento_bin="${magento_install_path}/bin/magento"
  local mftf_bin="${magento_install_path}/vendor/bin/mftf"

  logGroup "Configuring Magento Functional Testing Framework"

  logInfo "Setting Magento configuration"
  runCommand su vagrant -c "${magento_bin} config:set cms/wysiwyg/enabled disabled" || return 1
  runCommand su vagrant -c "${magento_bin} config:set admin/security/admin_account_sharing 1" || return 1
  runCommand su vagrant -c "${magento_bin} config:set admin/security/use_form_key 0" || return 1
  runCommand su vagrant -c "${magento_bin} cache:clean config full_page" || return 1

  logInfo "Building project"
  runCommand su vagrant -c "${mftf_bin} build:project" || return 1

  logInfo "Setting up MFTF environment"
  runCommand sed --follow-symlinks -i "s|MAGENTO_BASE_URL=.*|MAGENTO_BASE_URL=${magento_base_url}|g" "${magento_install_path}/dev/tests/acceptance/.env" || return 1
  runCommand sed --follow-symlinks -i "s|MAGENTO_BACKEND_NAME=.*|MAGENTO_BACKEND_NAME=${magento_admin_uri}|g" "${magento_install_path}/dev/tests/acceptance/.env" || return 1
  runCommand sed --follow-symlinks -i "s|MAGENTO_ADMIN_USERNAME=.*|MAGENTO_ADMIN_USERNAME=${magento_admin_username}|g" "${magento_install_path}/dev/tests/acceptance/.env" || return 1
  runCommand sed --follow-symlinks -i "s|MAGENTO_ADMIN_PASSWORD=.*|MAGENTO_ADMIN_PASSWORD=${magento_admin_password}|g" "${magento_install_path}/dev/tests/acceptance/.env" || return 1

  runCommand su vagrant -c "cp ${magento_install_path}/dev/tests/acceptance/.htaccess.sample ${magento_install_path}/dev/tests/acceptance/.htaccess" || return 1
  runCommand su vagrant -c "cp ${magento_install_path}/dev/tests/acceptance/.credentials.example ${magento_install_path}/dev/tests/acceptance/.credentials" || return 1

  if versionGTE "${magento_version}" "2.4" && [[ -n "${magento_otp_shared_secret}" ]]; then
    logInfo "Configuring two-factor authentication"
    runCommand su vagrant -c "${magento_bin} config:set twofactorauth/general/force_providers google" || return 1
    runCommand su vagrant -c "${magento_bin} config:set twofactorauth/google/otp_window 60" || return 1
    runCommand su vagrant -c "${magento_bin} security:tfa:google:set-secret ${magento_admin_username} ${magento_otp_shared_secret}" || return 1
    runCommand sed --follow-symlinks -i "s|OTP_SHARED_SECRET$|OTP_SHARED_SECRET=${magento_otp_shared_secret}|g" "${magento_install_path}/dev/tests/acceptance/.credentials" || return 1
  fi
}
