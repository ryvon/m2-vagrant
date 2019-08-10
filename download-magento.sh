#!/usr/bin/env bash

. ./etc/env

export SETUP_LOG="./log/setup.log"
export VAGRANT_ROOT="."
export COMPOSER_HOME="./.composer"
export COMPOSER_BIN="./.composer/composer.phar"

. ./scripts/setup/composer.sh

if [[ ! -d "${VAGRANT_ROOT}/source" ]]; then
  mkdir "${VAGRANT_ROOT}/source"
fi

if [[ ! -f "${VAGRANT_ROOT}/source/${MAGENTO_ARCHIVE}" ]]; then
  MAGENTO_SOURCE="${VAGRANT_ROOT}/source/magento-${MAGENTO_REPO_VERSION}"
  if [[ ! -f "${MAGENTO_SOURCE}/composer.json" ]]; then
    if [[ ! -d ${MAGENTO_SOURCE} ]]; then
      mkdir "${MAGENTO_SOURCE}"
    fi

    MAGENTO_REPO_REQUEST=${MAGENTO_REPO_NAME}
    if [[ -n "${MAGENTO_REPO_VERSION}" ]]; then
      MAGENTO_REPO_REQUEST="${MAGENTO_REPO_REQUEST}=${MAGENTO_REPO_VERSION}"
    fi

    echo "Downloading ${MAGENTO_REPO_REQUEST} from ${MAGENTO_REPO_URL}"
    ${COMPOSER_BIN} --ignore-platform-reqs --no-interaction --no-progress \
      create-project "${MAGENTO_REPO_REQUEST}" "${MAGENTO_SOURCE}" \
      --repository-url="${MAGENTO_REPO_URL}"
    if [[ $? -ne 0 ]]; then
      echo " - Failed to download Magento"
      exit 1
    fi
  fi

  echo "Archiving Magento from '${MAGENTO_SOURCE}' to '${VAGRANT_ROOT}/source/${MAGENTO_ARCHIVE}'"

  pushd "${MAGENTO_SOURCE}" >/dev/null || {
    echo " - Failed to change directory"
    exit 1
  }
  tar cf "../${MAGENTO_ARCHIVE}" .
  RESULT=$?
  popd >/dev/null || {
    echo " - Failed to change directory"
    exit 1
  }

  if [[ ${RESULT} -ne 0 ]]; then
    echo " - Failed to create Magento archive"
    exit 1
  fi
else
  echo "Magento archive already created"
fi

if [[ ! -f "${VAGRANT_ROOT}/source/${MAGENTO_SAMPLE_DATA_ARCHIVE}" ]]; then
  SAMPLE_DATA_SOURCE="${VAGRANT_ROOT}/source/magento-sample-data-${MAGENTO_SAMPLE_DATA_VERSION}"
  if [[ ! -d "${SAMPLE_DATA_SOURCE}" ]]; then
    echo "Downloading sample data from https://github.com/magento/magento2-sample-data.git"

    if [[ -n "${MAGENTO_SAMPLE_DATA_VERSION}" ]]; then
      git clone https://github.com/magento/magento2-sample-data.git --single-branch --branch "${MAGENTO_SAMPLE_DATA_VERSION}" "${SAMPLE_DATA_SOURCE}"
    else
      git clone https://github.com/magento/magento2-sample-data.git "${SAMPLE_DATA_SOURCE}"
    fi

    if [[ $? -ne 0 ]]; then
      echo " - Failed to download Magento Sample Data"
      exit 1
    fi
  fi

  echo "Archiving sample data from '${SAMPLE_DATA_SOURCE}' to '${VAGRANT_ROOT}/source/${MAGENTO_SAMPLE_DATA_ARCHIVE}'"

  pushd "${SAMPLE_DATA_SOURCE}" >/dev/null || {
    echo " - Failed to change directory"
    exit 1
  }
  tar cf "../${MAGENTO_SAMPLE_DATA_ARCHIVE}" .
  RESULT=$?
  popd >/dev/null || {
    echo " - Failed to change directory"
    exit 1
  }

  if [[ ${RESULT} -ne 0 ]]; then
    echo " - Failed to create sample data archive"
    exit 1
  fi
else
  echo "Sample data archive already created"
fi
