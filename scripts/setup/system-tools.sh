#!/usr/bin/env bash
set -e

[[ -z ${SETUP_LOG} ]] && exit 1

echo Installing system tools
{
  apt-get -y install apt-transport-https bash-completion ca-certificates curl \
    git lsb-release unzip zip
} >>"${SETUP_LOG}"
