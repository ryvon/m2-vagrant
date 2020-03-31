#!/usr/bin/env bash

getNodeVersion() {
  getAppVersion "node" "--version" false 's/^v\([^ ]*\)$/\1/'
  return $?
}

getGruntCliVersion() {
  getAppVersion "grunt" "--version" false 's/^grunt-cli v\([^ ]*\)$/\1/'
  return $?
}

getGulpVersion() {
  getAppVersion "gulp" "--version" "CLI version" 's/^.*version: \([^ ]*\)$/\1/'
  return $?
}

installNodeJs() {
  local major_version=$1

  logGroup "Installing nodejs v${major_version}.x"

  local existing_version
  existing_version=$(getNodeVersion)
  if [[ -n "${existing_version}" ]]; then
    logInfo "nodejs already installed (${existing_version})"
    return 0
  fi

  # We can't use runCommand due to the 'Warning: apt-key output should not be parsed (stdout is not a terminal)' stderr
  # output
  logDebug "Running command 'curl -sL \"https://deb.nodesource.com/setup_${major_version}.x\" | bash -'"
  local nodesource_output
  nodesource_output=$(curl -sL "https://deb.nodesource.com/setup_${major_version}.x" | bash - 2>&1)
  logDebug "Output: ${nodesource_output}"

  runCommand apt-get -y install nodejs || return 1
}

installGruntCli() {
  logGroup "Installing grunt-cli"

  local existing_version
  existing_version=$(getGruntCliVersion)
  if [[ -n "${existing_version}" ]]; then
    logInfo "grunt-cli already installed (${existing_version})"
    return 0
  fi

  runCommand npm install --loglevel=error --global grunt-cli || return 1
}

installGulp() {
  logGroup "Installing gulp"

  local existing_version
  existing_version=$(getGulpVersion)
  if [[ -n "${existing_version}" ]]; then
    logInfo "grunt already installed (${existing_version})"
    return 0
  fi

  runCommand npm install --loglevel=error --global gulp || return 1
}
