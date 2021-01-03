#!/usr/bin/env bash
# shellcheck disable=SC2164
cd "$(dirname "${BASH_SOURCE[0]}")"
# Upload all packages to a Nexus3 server, with a raw repository named 'gradle-distribution
NEXUS_SERVER="${NEXUS_SERVER:-127.0.0.1}"
NEXUS_RAW_REPO="${NEXUS_RAW_REPO:-gradle-distribution}"
DIST_DIR="${1:-build/distribution}"
for file in "${DIST_DIR}"/*; do
  file_name="$(basename "${file}")"
  curl -v --user "${NEXUS_USER:-admin}:${NEXUS_PASSWORD:-admin123}" --upload-file \
    "${file}" \
    "http://${NEXUS_SERVER}/repository/${NEXUS_RAW_REPO}/${file_name}"
done
echo "open http://${NEXUS_SERVER}/service/rest/repository/browse/${NEXUS_RAW_REPO}/" for file lists.
