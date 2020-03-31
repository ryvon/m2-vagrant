#!/usr/bin/env bash

restartServices() {
  logGroup "Restarting services"

  logInfo "Restarting apache2"
  runCommand service apache2 restart || return 1

  logInfo "Restarting mysql"
  runCommand service mysql restart || return 1

  logInfo "Restarting mailhog"
  runCommand service mailhog restart || return 1
}

updateSystem() {
  logGroup "Updating system"

  runCommand apt-get update || return 1
  runCommand apt-get -y upgrade || return 1
}

installSystemTools() {
  logGroup "Installing system tools"

  runCommand apt-get -y install apt-transport-https bash-completion ca-certificates curl git lsb-release unzip zip \
    mutt ncdu htop || return 1
}

installSwapFile() {
  local swap_file=$1
  local swap_size=$2

  logGroup "Installing swap file"

  if grep -q "${swap_file}" /etc/fstab; then
    logInfo "Swap file alredy installed"
    return 0
  fi

  runCommand fallocate -l "${swap_size}" "${swap_file}" || return 1
  runCommand chown root:root "${swap_file}" || return 1
  runCommand chmod 600 "${swap_file}" || return 1
  runCommand mkswap "${swap_file}" || return 1
  runCommand swapon "${swap_file}" || return 1

  if ! echo "${swap_file}   none    swap    sw    0   0" >>/etc/fstab; then
    logError "Failed to add swap to fstab"
    return 1
  fi
}

installSshKey() {
  local ssh_config_path=$1
  local ssh_public_key_file=$2

  logGroup "Installing SSH key"

  if [[ ! -f "${ssh_public_key_file}" ]]; then
    logError "Public key \"${ssh_public_key_file}\" not found"
    return 1
  fi

  local ssh_public_key
  ssh_public_key=$(cat "${ssh_public_key_file}")

  if [[ -f "${ssh_config_path}/authorized_keys" ]] && grep -q "${ssh_public_key}" "${ssh_config_path}/authorized_keys"; then
    logInfo "SSH key already installed"
    return 0
  fi

  if [[ ! -d "${ssh_config_path}" ]]; then
    runCommand mkdir -p "${ssh_config_path}" || return 1
    runCommand chmod g-rwx,o-rwx "${ssh_config_path}" || return 1
  fi

  if [[ ! -f "${ssh_config_path}/authorized_keys" ]]; then
    runCommand touch "${ssh_config_path}/authorized_keys" || return 1
    runCommand chmod g-rwx,o-rwx "${ssh_config_path}/authorized_keys" || return 1
  fi

  echo "${ssh_public_key}" >>"${ssh_config_path}/authorized_keys"

  if [[ ! -f "${ssh_config_path}/authorized_keys" ]] || ! grep -q "${ssh_public_key}" "${ssh_config_path}/authorized_keys"; then
    logError "Failed to install key, unknown error"
    return 1
  fi
}
