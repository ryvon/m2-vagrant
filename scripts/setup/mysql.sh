#!/usr/bin/env bash
set -e

[[ -z ${SETUP_LOG} ]] && exit 1

echo "Installing mysql"
{
  apt-get -y install mysql-server

  echo "[mysqld]" >/etc/mysql/conf.d/magento.cnf
  echo "innodb_buffer_pool_size=1G" >>/etc/mysql/conf.d/magento.cnf

  mysql -u root <<EOSQL
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO ${MYSQL_USER}@'localhost';
FLUSH PRIVILEGES;
EOSQL

  service mysql restart
} >"${SETUP_LOG}-mysql"
