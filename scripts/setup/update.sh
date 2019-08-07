#!/usr/bin/env bash
set -e

[[ -z ${SETUP_LOG} ]] && exit 1

echo Updating system
apt-get update >>"${SETUP_LOG}-update"
apt-get -y upgrade >>"${SETUP_LOG}-update"
