#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

IMAGE1="${1:-}"
IMAGE2="${2:-}"

# Output more information that is out of sync
DEBUG="${DEBUG:-}"

# Allow image2 to have more tags than image1
INCREMENTAL="${INCREMENTAL:-}"

SELF="$(basename "${BASH_SOURCE[0]}")"

function check() {
    local image1="${1:-}"
    local image2="${2:-}"

    if [[ "${image1}" == "" ]] || [[ "${image2}" == "" ]]; then
        echo "Compares whether the synchronization of the two images is exactly the same"
        echo "Need to install jq and skopeo"
        echo "Usage:"
        echo " ${SELF}: <image1> <image2>"
        echo " ${SELF}: <image1:tag> <image2:tag>"
        echo "Env:"
        echo " DEBUG=true       # Output more information that is out of sync"
        echo " INCREMENTAL=true # Allow image2 to have more tags than image1"
        return 2
    fi

    if [[ "${image1}" =~ ":" ]]; then
        if [[ "${image2}" =~ ":" ]]; then
            return 0
        else
            echo "${SELF}: ERROR: ${image1} and ${image2} must both be full images or not be tag references" >&2
            return 2
        fi
    else
        if [[ "${image2}" =~ ":" ]]; then
            echo "${SELF}: ERROR: ${image1} and ${image2} must both be full images or not be tag references" >&2
            return 2
        else
            return 0
        fi
    fi
}

function inspect() {
    local image="${1:-}"
    if [[ "${DEBUG}" == "true" ]]; then
        echo skopeo inspect --retry-times=3 --raw --tls-verify=false "docker://${image}" >&2
    fi
    skopeo inspect --retry-times=3 --raw --tls-verify=false "docker://${image}"
}

function list-tags() {
    local image="${1:-}"
    if [[ "${DEBUG}" == "true" ]]; then
        echo skopeo list-tags --retry-times=3 --tls-verify=false "docker://${image}" >&2
    fi
    skopeo list-tags --retry-times=3 --tls-verify=false "docker://${image}"
}

function diff-image() {
    local image1="${1:-}"
    local image2="${2:-}"

    if [[ "$image1" =~ ":" ]]; then
        local inspect1="$(inspect ${image1} | jq -S 'del( .manifests[]?.mediaType, .layers[]?.mediaType, .config?, .mediaType?, .schemaVersion?, .signatures?)')"
        local inspect2="$(inspect ${image2} | jq -S 'del( .manifests[]?.mediaType, .layers[]?.mediaType, .config?, .mediaType?, .schemaVersion?, .signatures?)')"
        local diff_raw=$(diff --unified <(echo "${inspect1}") <(echo "${inspect2}"))

        if [[ "${diff_raw}" != "" ]]; then
            echo "${SELF}: UNSYNC: ${image1} and ${image2} are not in synchronized" >&2
            if [[ "${DEBUG}" == "true" ]]; then
                echo "DEBUG: image1 ${image1}:" >&2
                echo "${inspect1}" >&2
                echo "DEBUG: image2 ${image2}:" >&2
                echo "${inspect2}" >&2
                echo "diff:" >&2
                echo "${diff_raw}" >&2
            fi
            return 1
        fi
        echo "${SELF}: SYNC: ${image1} and ${image2} are in synchronized" >&2
        echo "${inspect1}"
    else
        local inspect1="$(list-tags ${image1} | jq -S '.')"
        local inspect2="$(list-tags ${image2} | jq -S '.')"
        local diff_raw="$(diff --unified <(echo "${inspect1}" | jq -S '.Tags[]' | tr -d '"') <(echo "${inspect2}" | jq -S '.Tags[]' | tr -d '"'))"
        local diff_data="$(echo "${diff_raw}" | grep -v ' ' | grep -v -E '^---' | grep -v -E '^\+\+\+')"

        if [[ "${INCREMENTAL}" == "true" ]]; then
            diff_data="$(echo "${diff_data}" | grep -v -E '^\+')"
        fi

        if [[ "${diff_data}" != "" ]]; then
            echo "${SELF}: UNSYNC: ${image1} and ${image2} are not in synchronized" >&2
            if [[ "${DEBUG}" == "true" ]]; then
                echo "DEBUG: image1 ${image1}:" >&2
                echo "${inspect1}" >&2
                echo "DEBUG: image2 ${image2}:" >&2
                echo "${inspect2}" >&2
                echo "DEBUG: diff:" >&2
                echo "${diff_data}" >&2
            fi
            return 1
        fi
        echo "${SELF}: SYNC: ${image1} and ${image2} are in synchronized" >&2
        echo "${inspect1}"
    fi
    return 0
}

function main() {
    local image1="${1:-}"
    local image2="${2:-}"

    raw=$(diff-image "${image1}" "${image2}")
    if [[ "${image1}" =~ ":" ]]; then
        return 0
    fi

    local list=$(echo "${raw}" | jq '.Tags[]' | tr -d '"')
    local total=$(echo "${list}" | wc -l | tr -d ' ')
    local count=0
    local unsync=()

    for tag in ${list}; do
        count=$((count + 1))
        echo "${SELF}: DIFF ${count}/${total}: ${tag}"
        diff-image "${image1}:${tag}" "${image2}:${tag}" >/dev/null || unsync+=("${tag}")
    done

    if [[ "${#unsync[@]}" -gt 0 ]]; then
        echo "${SELF}: UNSYNC: ${image1} and ${image2} are not in synchronized, there are unsynchronized tags ${#unsync[@]}/${total}: ${unsync[*]}" >&2
        return 1
    fi
}

check "${IMAGE1}" "${IMAGE2}"
main "${IMAGE1}" "${IMAGE2}"
