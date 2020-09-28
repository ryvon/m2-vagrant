#!/usr/bin/env bash

getMariadbVersion() {
  getAppVersion "mysql" "--version" 'Distrib' 's/.*Distrib \([A-Za-z0-9\.-]*\).*/\1/'
  return $?
}

installMariadb() {
  local version=$1

  logGroup "Installing mariadb-server-${version}"

  existing_version=$(getMariadbVersion)
  if [[ -n "${existing_version}" ]]; then
    logInfo "mariadb-server already installed (${existing_version})"
    return 0
  fi

  curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash -s -- \
    --mariadb-server-version="mariadb-${version}" 2>/dev/null || return 1
  runCommand apt-get -y install "mariadb-server-${version}" || return 1
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
