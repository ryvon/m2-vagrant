#!/usr/bin/env bash

getMysqlVersion() {
  getAppVersion "mysql" "--version" 'Distrib' 's/.*Distrib \([A-Za-z0-9\.-]*\).*/\1/'
  return $?
}

installMysql() {
  logGroup "Installing mysql-server"

  existing_version=$(getMysqlVersion)
  if [[ -n "${existing_version}" ]]; then
    logInfo "mysql-server already installed (${existing_version})"
    return 0
  fi

  runCommand apt-get -y install mysql-server || return 1
}
