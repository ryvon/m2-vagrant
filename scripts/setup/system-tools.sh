#!/usr/bin/env bash
set -e

[[ -z ${SETUP_LOG} ]] && exit 1

echo "Installing system tools"
{
  apt-get -y install apt-transport-https bash-completion ca-certificates curl \
    git lsb-release unzip zip mutt ncdu htop

  echo " - Installing nodejs" >&2
  curl -sL https://deb.nodesource.com/setup_10.x | bash -
  apt-get -y install nodejs

  echo " - Installing grunt-cli and gulp globally" >&2
  npm install --loglevel=error -g grunt-cli gulp
} >>"${SETUP_LOG}"
