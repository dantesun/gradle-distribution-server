#!/usr/bin/env bash
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

validate() {
  local file="${1}"
  local file_checksum
  file_checksum="$(openssl sha256 -r "${file}" | cut -d ' ' -f 1)"
  local checksum_file="${file}.sha256"
  [ -f "${checksum_file}" ] || {
    echo "Downloading ${checksum_file}"
    curl -sL "https://services.gradle.org/distributions/${checksum_file}" -o "${checksum_file}"
  }

  local offical_checksum
  offical_checksum="$(cat "${checksum_file}")"
  if [[ "${file_checksum}" == "${offical_checksum}" ]]; then
    echo "${file} checksum is ok"
  else
    echo "${file} checksum is NOT ok."
  fi
}

if (($# == 0)); then
  echo "Validating all files in ${PWD}"
  for f in *.zip; do
    validate "${f}"
  done
else
  version="${1}"
  type="${2:-bin}"
  file="gradle-${version}-${type}.zip"
  [ -f "${file}" ] || {
    echo "${file} doesn't exist!"
    exit 1
  }
  validate "${file}"
fi
