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

importDatabase() {
  local database_username=$1
  local database_password=$2
  local database_name=$3
  local import_file=$4

  if [[ ! -f "${import_file}" ]]; then
    logError "Database backup not found at \"${import_file}\""
    return 1
  fi

  local temp_root
  local real_import_file="${import_file}"

  temp_root=$(mktemp -d)

  if isArchive "${import_file}"; then
    logInfo "Extracting database from ${import_file}"

    extractArchive "${import_file}" "${temp_root}" || return 1

    for file in "${temp_root}"/*; do
      real_import_file="${file}"
      break 1
    done
  fi

  if [[ "${real_import_file}" != *.sql ]]; then
    logError "Unknown database format \"${real_import_file}\""
    return 1
  fi

  logInfo "Importing database from \"${real_import_file}\""

  local database_error_file
  local time_file

  database_error_file="${temp_root}/database.txt"
  time_file="${temp_root}/time.txt"

  TIMEFORMAT="%lR"
  time (mysql --user="${database_username}" --password="${database_password}" "${database_name}" <"${real_import_file}" 2>"${database_error_file}") >"${time_file}" 2>&1

  if [[ -n "$(cat "${database_error_file}")" ]]; then
    logError "Failed to import database, $(cat "${database_error_file}")"
    runCommand rm -rf "${temp_root}" || return 1
    return 1
  fi

  logDebug "Took $(cat "${time_file}") to import database"
  runCommand rm -rf "${temp_root}" || return 1

  return 0
}
