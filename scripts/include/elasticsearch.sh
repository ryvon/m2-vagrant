#!/usr/bin/env bash

getElasticsearchVersion() {
  getAppVersion "curl" "localhost:9200" '"number"' 's/^.*"number" : "\([^"]*\)".*$/\1/' 2>/dev/null
  return $?
}

installElasticsearch() {
  logGroup "Installing elasticsearch"

  local existing_version
  existing_version=$(getElasticsearchVersion)
  if [[ -n "${existing_version}" ]]; then
    logInfo "elasticsearch already installed (${existing_version})"
    return 0
  fi

  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - >/dev/null 2>&1 || return 1
  echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" > /etc/apt/sources.list.d/elastic-7.x.list || return 1

  runCommand apt-get update || return 1
  runCommand apt-get -y install elasticsearch || return 1
  runCommand update-rc.d elasticsearch defaults 95 10 || return 1
  runCommand service elasticsearch start || return 1
}
