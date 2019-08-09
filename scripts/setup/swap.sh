#!/usr/bin/env bash
set -e

[[ -z ${SETUP_LOG} ]] && exit 1

echo "Installing swap file"
{
  fallocate -l 1G /var/swap.1
  chown root:root /var/swap.1
  chmod 600 /var/swap.1
  mkswap /var/swap.1
  swapon /var/swap.1

  echo "/var/swap.1   none    swap    sw    0   0" | sudo tee -a /etc/fstab
} >>"${SETUP_LOG}"
