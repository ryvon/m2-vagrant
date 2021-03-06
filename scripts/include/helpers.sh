#!/usr/bin/env bash

SETUP_LOG_FILE="${LOG_ROOT}/setup-$(date +"%Y%m%d").log"
SETUP_LOG_DATE_FORMAT="%r"

COLOR_NONE='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_GRAY='\033[1;30m'
COLOR_WHITE='\033[1;37m'

writeToLogFile() {
  local log_type=$1
  local log_line=$2

  local prefixed_log_line
  # shellcheck disable=SC2001
  prefixed_log_line="$(sed "s/^/$(date +"${SETUP_LOG_DATE_FORMAT}") [${log_type}] /" <<<"$log_line")"

  echo "${prefixed_log_line}" >>"${SETUP_LOG_FILE}"
}

logGroup() {
  local log_line=$*

  echo -e " + ${COLOR_WHITE}${log_line}${COLOR_NONE}" >&2
  echo "$(date +"${SETUP_LOG_DATE_FORMAT}") ${log_line}" >>"${SETUP_LOG_FILE}"
}

logError() {
  local log_line=$*

  # shellcheck disable=SC2001
  echo -e "$(sed "s/^/  $(echo -e "${COLOR_RED} ! ${COLOR_NONE}")/" <<<"$log_line")" >&2

  writeToLogFile "ERROR" "${log_line}"
}

logSuccess() {
  local log_line=$*

  # shellcheck disable=SC2001
  echo -e "$(sed "s/^/  $(echo -e "${COLOR_GREEN} - ${COLOR_NONE}")/" <<<"$log_line")" >&2

  writeToLogFile "SUCCESS" "${log_line}"
}

logInfo() {
  local log_line=$*

  # shellcheck disable=SC2001
  echo -e "$(sed 's/^/   - /' <<<"$log_line")" >&2

  writeToLogFile "INFO" "${log_line}"
}

logDebug() {
  local log_line=$*

  if [[ -z "${log_line}" ]]; then
    return 0
  fi

  if [[ "${VERBOSE}" == true ]]; then
    # shellcheck disable=SC2001
    echo -e "$(sed "s/^/  $(echo -e "${COLOR_GRAY}")   /" <<<"$log_line")${COLOR_NONE}" >&2
  fi

  writeToLogFile "DEBUG" "${log_line}"
}

runCommand() {
  local command=$*

  local command_errors
  local command_output

  command_errors_file=$(mktemp)

  logDebug "Running command '${command}'"

  command_output=$("$@" 2>"${command_errors_file}")
  command_result=$?

  if [[ -n "${command_output}" ]]; then
    logDebug " > Exit code: ${command_result}"
    logDebug " > Output: ${command_output}"
  elif [[ ${command_result} -ne 0 ]]; then
    logDebug " > Exit code: ${command_result}"
    logDebug " > Output: none"
  fi

  command_errors=$(cat "${command_errors_file}")
  rm "${command_errors_file}"

  if [[ ${command_result} -ne 0 ]]; then
    if [[ -z "${command_errors}" ]]; then
      logError "Unknown error"
    else
      logError "${command_errors}"
    fi
    return 1
  fi

  if [[ -n "${command_errors}" ]]; then
    logDebug " > Command reported success but had stderr output: ${command_errors}"
  fi
}

getAppVersion() {
  local app_executable=$1
  local app_version_switch=$2
  local output_grep=$3
  local output_sed_extract=$4
  local app_run_as_vagrant=$5

  local app_path
  local app_version
  local app_version_number

  app_path=$(command -v "${app_executable}")
  if [[ -z "${app_path}" ]]; then
    return 1
  fi

  # We pipe stderr to stdout due to 'java -version' outputting to stderr
  if [[ "${app_run_as_vagrant}" == true ]]; then
    app_version=$(su vagrant -c "${app_path} ${app_version_switch}" 2>&1)
  else
    app_version=$("${app_path}" "${app_version_switch}" 2>&1)
  fi

  if [[ "${output_grep}" != false ]] && [[ -n "${output_grep}" ]]; then
    # shellcheck disable=SC2086
    app_version=$(echo "${app_version}" | grep -n "${output_grep}")
  fi

  # shellcheck disable=SC2086
  app_version_number=$(echo "${app_version}" | sed "${output_sed_extract}")

  if [[ "${app_version_number}" == "${app_version}" ]]; then
    logError "Failed to parse version string \"${app_version}\""
    return 1
  fi

  echo "${app_version_number}"
}

versionGTE() {
  # https://stackoverflow.com/a/24067243
  local lowest_version="$(printf '%s\n' "$@" | sort -V | head -n 1)"
  if [[ "${lowest_version}" != "$2" ]]; then
    return 1
  fi
}

testUrl() {
  local label=$1
  local check_url=$2
  local check_content=$3

  local curl_error_file
  local curl_cookie_file
  local curl_response
  local curl_error

  curl_cookie_file=$(mktemp)
  curl_error_file=$(mktemp)
  curl_response="$(curl --silent --show-error --location --insecure --max-time 20 --connect-timeout 5 \
    --cookie "${curl_cookie_file}" "${check_url}" 2>"${curl_error_file}")"

  curl_error=$(cat "${curl_error_file}")
  rm "${curl_error_file}"
  rm "${curl_cookie_file}"

  if [[ -n "${curl_error}" ]]; then
    logError "${label} $(printf '%-40s' "${check_url}") Failed to fetch: ${curl_error}"
    return 1
  fi

  if [[ ${curl_response} =~ ${check_content} ]]; then
    logSuccess "${label} ${check_url}"
    return 0
  fi

  logError "${label} $(printf '%-35s' "${check_url}") Expected content not found"
  logDebug "${check_url} content: ${curl_response}"
  return 1
}

isArchive() {
  local file=$1

  if [[ "${file}" == *.tar.gz ]]; then
    return 0
  elif [[ "${file}" == *.tar.bz2 ]]; then
    return 0
  elif [[ "${file}" == *.tar ]]; then
    return 0
  else
    return 1
  fi
}

createArchive() {
  local archive_file=$1
  local path_to_compress=$2

  local tar_switch
  if [[ "${archive_file}" == *.tar.gz ]]; then
    tar_switch="-czf"
  elif [[ "${archive_file}" == *.tar.bz2 ]]; then
    tar_switch="-cjf"
  elif [[ "${archive_file}" == *.tar ]]; then
    tar_switch="-cf"
  else
    logError "Unknown archive type"
    return 1
  fi

  pushd "${path_to_compress}" >/dev/null || return 1
  runCommand tar "${tar_switch}" "${archive_file}" . || return 1
  popd >/dev/null || return 1
}

extractArchive() {
  local archive_file=$1
  local path_to_extract=$2

  local tar_switch
  if [[ "${archive_file}" == *".tar.gz" ]]; then
    tar_switch="-xzf"
  elif [[ "${archive_file}" == *".tar.bz2" ]]; then
    tar_switch="-xjf"
  elif [[ "${archive_file}" == *".tar" ]]; then
    tar_switch="-xf"
  else
    logError "Unknown archive type"
    return 1
  fi

  runCommand tar "${tar_switch}" "${archive_file}" --directory "${path_to_extract}" || return 1
}
