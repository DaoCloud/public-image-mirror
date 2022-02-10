#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

source "$(dirname "${BASH_SOURCE}")/helper.sh"
cd "${ROOT}"

DEBUG="${DEBUG:-}"
INCREMENTAL="${INCREMENTAL:-}"
QUICKLY="${QUICKLY:-}"
SYNC="${SYNC:-}"
PARALLET="${PARALLET:-0}"
PARALLET_JOBS="${PARALLET_JOBS:-4}"
EXCLUDE="$(helper::exclude)"

declare -A DOMAIN_MAP=()

function wait_jobs() {
    local job_num=${1:-3}
    local perc=$(jobs -p | wc -l)
    while [ "${perc}" -gt "${job_num}" ]; do
        sleep 1
        perc=$(jobs -p | wc -l)
    done
}

function sync_with_domain() {
    local domain="${1}"

    local list=$(echo ${DOMAIN_MAP[${domain}]} | tr ' ' '\n' | shuf)
    for image in ${list}; do
        regex="${DEFAULT_REGEX}"
        if [[ "${image#*/}" =~ ":" ]]; then
            regex="${image##*:}"
            image="${image%:*}"
        fi
        local to="$(helper::replace_domain "${domain}/${image}")"

        local logfile="${to//\//_}_sync.log"
        echo >"${logfile}"

        DEBUG="${DEBUG}" SYNC="${SYNC}" QUICKLY="${QUICKLY}" INCREMENTAL="${INCREMENTAL}" PARALLET="${PARALLET}" FOCUS="${regex}" SKIP="${EXCLUDE}" ./hack/diff-image.sh "${domain}/${image}" "${to}" 2>&1 | tee -a "${logfile}" || {
            echo "Error: diff image ${domain}/${image} $(helper::replace_domain "${domain}/${image}")"
        }
    done
}

function main() {

    for image in $(helper::get_source); do
        key="${image%%/*}"
        val="${image#*/}"
        if [[ -v "DOMAIN_MAP[${key}]" ]]; then
            DOMAIN_MAP["${key}"]+=" ${val}"
        else
            DOMAIN_MAP["${key}"]="${val}"
        fi
    done

    for domain in "${!DOMAIN_MAP[@]}"; do
        if [[ "${PARALLET_JOBS}" -eq 0 ]]; then
            sync_with_domain "${domain}"
        else
            wait_jobs "${PARALLET_JOBS}"
            sync_with_domain "${domain}" &
        fi
    done

    wait
}

trap "trap - SIGTERM && kill 0 && echo exit..." SIGTERM SIGINT

main
