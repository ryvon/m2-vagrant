#!/usr/bin/env bash

. ./etc/env

export SETUP_LOG="./log/setup.log"
export VAGRANT_ROOT="."
export COMPOSER_HOME="./.composer"
export COMPOSER_BIN="./.composer/composer.phar"

. ./scripts/setup/composer.sh

if [[ ! -d "${VAGRANT_ROOT}/archive" ]]; then
  mkdir "${VAGRANT_ROOT}/archive"
fi

export MAGENTO_ROOT="${VAGRANT_ROOT}/magento2"
if [[ ! -f "${MAGENTO_ROOT}/composer.json" ]]; then
  if [[ ! -d ${MAGENTO_ROOT} ]]; then
    mkdir "${MAGENTO_ROOT}"
  fi

  MAGENTO_REPO_REQUEST=${MAGENTO_REPO_NAME}
  if [[ -n "${MAGENTO_REPO_VERSION}" ]]; then
    MAGENTO_REPO_REQUEST="${MAGENTO_REPO_REQUEST}=${MAGENTO_REPO_VERSION}"
  fi

  echo "Downloading ${MAGENTO_REPO_REQUEST} from ${MAGENTO_REPO_URL}"
  ${COMPOSER_BIN} --ignore-platform-reqs --no-interaction --no-progress \
    create-project "${MAGENTO_REPO_REQUEST}" "${MAGENTO_ROOT}" \
    --repository-url="${MAGENTO_REPO_URL}"
  if [[ $? -ne 0 ]]; then
    echo "Failed to download Magento"
    exit 1
  fi
fi

export CURRENT_MAGENTO_ARCHIVE="magento-${MAGENTO_REPO_VERSION}.tar"
if [[ ! -f "${VAGRANT_ROOT}/archive/${CURRENT_MAGENTO_ARCHIVE}" ]]; then

  echo "Archiving Magento from '${MAGENTO_ROOT}' to '${VAGRANT_ROOT}/archive/${CURRENT_MAGENTO_ARCHIVE}'"

  pushd "${MAGENTO_ROOT}" >/dev/null || {
    echo "Failed to change directory"
    exit 1
  }
  tar cf "../archive/${CURRENT_MAGENTO_ARCHIVE}" .
  RESULT=$?
  popd >/dev/null || {
    echo "Failed to change directory"
    exit 1
  }

  if [[ ${RESULT} -ne 0 ]]; then
    echo "Failed to create Magento archive"
    exit 1
  fi
else
  echo "Magento archive already created"
fi

export SAMPLE_DATA_ROOT="${VAGRANT_ROOT}/magento2-sample-data"
if [[ ! -d "${SAMPLE_DATA_ROOT}" ]]; then
  echo "Downloading sample data from https://github.com/magento/magento2-sample-data.git"

  if [[ -n "${MAGENTO_SAMPLE_DATA_VERSION}" ]]; then
    git clone https://github.com/magento/magento2-sample-data.git --single-branch --branch ${MAGENTO_SAMPLE_DATA_VERSION} ${SAMPLE_DATA_ROOT}
  else
    git clone https://github.com/magento/magento2-sample-data.git ${SAMPLE_DATA_ROOT}
  fi

  if [[ $? -ne 0 ]]; then
    echo "Failed to download Magento Sample Data"
    exit 1
  fi
fi

export CURRENT_SAMPLE_DATA_ARCHIVE="sample-data-${MAGENTO_SAMPLE_DATA_VERSION}.tar"
if [[ ! -f "${VAGRANT_ROOT}/archive/${CURRENT_SAMPLE_DATA_ARCHIVE}" ]]; then
  echo "Archiving sample data from '${SAMPLE_DATA_ROOT}' to '${VAGRANT_ROOT}/archive/${CURRENT_SAMPLE_DATA_ARCHIVE}'"

  pushd "${SAMPLE_DATA_ROOT}" >/dev/null || {
    echo "Failed to change directory"
    exit 1
  }
  tar cf "../archive/${CURRENT_SAMPLE_DATA_ARCHIVE}" .
  RESULT=$?
  popd >/dev/null || {
    echo "Failed to change directory"
    exit 1
  }

  if [[ ${RESULT} -ne 0 ]]; then
    echo "Failed to create sample data archive"
    exit 1
  fi
else
  echo "Sample data archive already created"
fi
