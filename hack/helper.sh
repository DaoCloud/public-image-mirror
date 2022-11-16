#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

ROOT="${ROOT:-$(dirname "${BASH_SOURCE}")/..}"
DEFAULT_REGEX='^([a-z]+-)?[a-z]*[0-9]+(\.[0-9]+){1,2}'
SKOPEO="${SKOPEO:-skopeo}"
ROOT=$(realpath ${ROOT})
DOMAIN="${DOMAIN:-m.daocloud.io}"

function helper::replace_domain() {
    local domain="${1}"
    echo "${DOMAIN}/${domain}"
}

function helper::get_source() {
    local source="${1:-mirror.txt}"
    cat "${source}" | tr -d ' ' | grep -v -E '^$' | grep -v -E '^#'
}

function helper::exclude() {
    local exclude="${1:-exclude.txt}"
    local tmp=$(cat "${exclude}" | tr -d ' ' | grep -v -E '^$' | grep -v -E '^#' | tr '\n' '|')
    echo "${tmp%|}"
}
