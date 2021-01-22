#!/usr/bin/env bash
# shellcheck disable=SC2164
cd "$(dirname "${BASH_SOURCE[0]}")"

function usage() {
  echo "
Usage:
${BASH_SOURCE[0]} [-d DIRECTORY] -v PATTERN [-f] [-t bin|all]

          -f: Always fetch versions from Gradle website. Without '-f', it will only fetch the versions into
              ./build/versions.txt once unless you manually delete it.

-d DIRECTORY: The directory where Gradle distributions are stored.

  -v PATTERN: An Awk Regular Expression matches the Gradle version, it will be wrapped in '^PATTERN$'.
              NOTE:
              1. ALWAYS use single quotes around your pattern, ex: '(6.7|6.7.1)', '(6.*)'
                  '6.*' matches all 6.x.x versions.
              2. To match multiple versions, use '(version1|version2)'. For example, '(6.7|6.7.1)' matches two versions,
              3. To match a version range, use patterns like the following.
                 a. '[456].*' will match 4.x.x, 5.x.x and 6.xx.
                 b. '6.1.*' will match 6.1.x and '6.*' will match 6.x and 6.x.x
              4. Please see https://www.gnu.org/software/gawk/manual/html_node/Regexp-Usage.html for details.

  -t bin|all: The Archive type.
              'bin' means gradle-x.x.x-bin.zip which contains no source code.
              'all' means gradle-x.x.x-all.zip with source code.
Example:
  ${BASH_SOURCE[0]} -d ./build/distributions # download all distributions to directory
  ${BASH_SOURCE[0]} -d ./build/distributions -v 4.0.1 # download gradle-4.0.1-all.zip and gradle-4.0.1-bin.zip
  ${BASH_SOURCE[0]} -d ./build/distributions -v 4.0.1 -t all # download gradle-4.0.1-all.zip
  ${BASH_SOURCE[0]} -d ./build/distributions -v '(4.2.1|6.7)' -t all # download gradle-4.0.1-all.zip and gradle-6.7-all.zip
  ${BASH_SOURCE[0]} -d ./build/distributions -v '6.*' -t all # download gradle-6.x.x-all.zip
"
}

while (("$#")); do
  case "${1}" in
  -f)
    FORCED_VERSION_FETCH=1
    shift
    ;;
  -h)
    usage
    exit 0
    ;;
  -d)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
      DOWNLOAD_DIR=$2
      shift 2
    else
      echo "Error: Argument for $1 is missing" >&2
      exit 1
    fi
    ;;
  -v)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
      VERSIONS=$2
      shift 2
    else
      echo "Error: Argument for $1 is missing" >&2
      exit 1
    fi
    ;;
  -t)
    if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
      TYPE=$2
      case "${TYPE}" in
      bin | all) ;;
      *)
        echo "Only 'bin' and 'all' are allowed in -t!"
        exit 1
        ;;
      esac
      shift 2
    else
      echo "Error: Argument for $1 is missing" >&2
      exit 1
    fi
    ;;
  *) # unsupported flags
    echo "Error: Unsupported flag $1" >&2
    exit 1
    ;;
  esac
done

[ -z "${DOWNLOAD_DIR}" ] && {
  DOWNLOAD_DIR="build/distributions"
  mkdir -p "${DOWNLOAD_DIR}" || {
    echo "Can't creating ${DOWNLOAD_DIR}!"
    exit 1
  }
}

[ -z "${VERSIONS}" ] && {
  echo "Please use -v specify version range!"
  usage
  exit 1
}

[ -d build ] || {
  mkdir build
}

readonly VERSIONS_FILE="${PWD}/build/versions.txt"
function fetch_versions() {
  local released='select(.snapshot == false and .broken == false)'
  local not_rc='select(.version | index("-rc-") | not)'
  local not_milestone='select(.version | index("-milestone") | not)'
  curl -s "https://services.gradle.org/versions/all" | jq -r "map(${released} | ${not_rc} | ${not_milestone}) | .[].version"
}
#Determine whether to fetch Gradle versions or not.
FETCH_VERSIONS=1
if ((${FORCED_VERSION_FETCH:-0} == 1)); then
  FETCH_VERSIONS=1
elif ! [ -f "${VERSIONS_FILE}" ]; then
  FETCH_VERSIONS=1
else
  FETCH_VERSIONS=0
fi

if ((FETCH_VERSIONS == 1)); then
  echo "Fetch all official released versions of Gradle."
  fetch_versions | uniq | sort > "${VERSIONS_FILE}"
fi

function validate_distribution_file() {
  local file="${1}"
  local file_checksum
  file_checksum="$(openssl sha256 -r "${file}" | cut -d ' ' -f 1)"
  local checksum_file="${file}.sha256"
  [ -f "${checksum_file}" ] || {
    local file_name
    file_name=$(basename "${checksum_file}")
    echo "Downloading ${file_name}"
    curl -sL "https://services.gradle.org/distributions/${file_name}" -o "${checksum_file}"
  }

  local official_checksum
  official_checksum="$(cat "${checksum_file}")"
  if [[ "${file_checksum}" = "${official_checksum}" ]]; then
    echo "${file} checksum is ok"
  else
    echo "${file} checksum is NOT ok.(Expected: ${official_checksum}, Actual: ${file_checksum}"
  fi
}

echo "Generating aria2c downloading URLs."
[ -f urls.txt ] && {
  echo "Backup previous aria2c downloading URLs file."
  mv urls.txt{,.bak} || {
    echo "Failed to backup urls.txt"
    exit 1
  }
}

count=0
while IFS= read -r version; do
  case "${TYPE}" in
  bin | all)
  echo "https://services.gradle.org/distributions/gradle-${version}-${TYPE}.zip" >> urls.txt
  ((count++))
  ;;
  *)
  echo "https://services.gradle.org/distributions/gradle-${version}-all.zip" >> urls.txt
  echo "https://services.gradle.org/distributions/gradle-${version}-bin.zip" >> urls.txt
  count=$((count + 2))
    ;;
  esac
done< <(awk "/^${VERSIONS}$/{ print \$0 }" "${VERSIONS_FILE}")

if [[ "$count" -eq 0 ]]; then
  echo "No version is selected. Please check if '${VERSIONS}' is correct."
  exit 1
fi

if ! command -v "aria2c" >/dev/null; then
  echo "Please install aria2c at https://github.com/aria2/aria2!"
  exit 1
fi
echo "Start downloading, please see aria2c.log for details."
aria2c -l aria2c.log -d "${DOWNLOAD_DIR}" --continue=true -x 16 -s 2 -i urls.txt

for f in "${DOWNLOAD_DIR}"/*.zip; do
  validate_distribution_file "${f}"
done
