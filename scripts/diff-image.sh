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

# Compare only tags that are in both images
QUICKLY="${QUICKLY:-}"

# Exclude tags that do not need to be checked
EXCLUDED="${EXCLUDED:-}"

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
        echo " QUICKLY=true     # Compare only tags that are in both images"
        echo " EXCLUDED=true    # Exclude tags that do not need to be checked"
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
    local raw=$(skopeo inspect --raw --tls-verify=false "docker://${image}")
    if [[ "${raw}" == "" ]]; then
        echo "skopeo inspect --raw --tls-verify=false docker://${image}" >&2
        echo "ERROR: Failed to inspect ${image}" >&2
        return 1
    fi

    local schemaVersion=$(echo "${raw}" | jq -r '.schemaVersion')
    case "${schemaVersion}" in
    1)
        echo "${raw}" | jq -r '.fsLayers[].blobSum'
        ;;
    2)
        local mediaType=$(echo "${raw}" | jq -r '.mediaType // "" ')
        case "${mediaType}" in
        "application/vnd.docker.distribution.manifest.v2+json" | "")
            echo "${raw}" | jq -r '.layers[].digest'
            ;;
        "application/vnd.docker.distribution.manifest.list.v2+json")
            echo "${raw}" | jq -j '.manifests[] | .platform.architecture , " " , .platform.os , " " , .digest , "\n"' | sort
            ;;
        *)
            echo "skopeo inspect --raw --tls-verify=false docker://${image}" >&2
            if [[ "${DEBUG}" == "true" ]]; then
                echo "${raw}" >&2
            fi
            echo "${SELF}: ERROR: Unknown media type: ${mediaType}" >&2
            return 2
            ;;
        esac
        ;;
    *)
        echo "skopeo inspect --raw --tls-verify=false docker://${image}" >&2
        if [[ "${DEBUG}" == "true" ]]; then
            echo "${raw}" >&2
        fi
        echo "${SELF}: ERROR: Unknown schema version: ${schemaVersion}" >&2
        return 2
        ;;
    esac
}

function list-tags() {
    local image="${1:-}"
    local raw="$(skopeo list-tags --tls-verify=false "docker://${image}" | jq -r '.Tags[]' | sort)"

    if [[ "${EXCLUDED}" != "" ]]; then
        raw="$(echo "${raw}" | grep -v -E "${EXCLUDED}" || :)"
    fi
    echo "${raw}"
}

function diff-image-with-tag() {
    local image1="${1:-}"
    local image2="${2:-}"

    if [[ "${QUICKLY}" == "true" ]]; then
        local tag1="${image1##*:}"
        local tag2="${image2##*:}"
        if [[ "${tag1}" != "${tag2}" ]]; then
            echo "${SELF}: UNSYNC: ${image1} and ${image2} are not in synchronized" >&2
            return 1
        fi
        echo "${SELF}: SYNC: ${image1} and ${image2} are in synchronized" >&2
        return 0
    fi

    local inspect1="$(inspect ${image1})"
    local inspect2="$(inspect ${image2})"
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
}

function diff-image() {
    local image1="${1:-}"
    local image2="${2:-}"

    local tags1="$(list-tags ${image1})"
    local tags2="$(list-tags ${image2})"
    local diff_raw="$(diff --unified <(echo "${tags1}") <(echo "${tags2}") | grep -v -E '^---' | grep -v -E '^\+\+\+' || :)"
    local diff_data="$(echo "${diff_raw}" | grep -v -E '^ ' || :)"

    if [[ "${INCREMENTAL}" == "true" ]]; then
        diff_data="$(echo "${diff_data}" | grep -v -E '^\+' || :)"
    fi

    if [[ "${diff_data}" != "" ]]; then
        echo "${SELF}: UNSYNC-TAGS: ${image1} and ${image2} are not in synchronized" >&2
        if [[ "${DEBUG}" == "true" ]]; then
            echo "DEBUG: image1 ${image1}:" >&2
            echo "${tags1}" >&2
            echo "DEBUG: image2 ${image2}:" >&2
            echo "${tags2}" >&2
            echo "DEBUG: diff:" >&2
            echo "${diff_data}" >&2
        fi
        for tag in $(echo "${diff_raw}" | grep -E '^-' || :); do
            tag="${tag#-}"
            echo "${SELF}: UNSYNC: ${image1}:${tag} and ${image2}:${tag} are not in synchronized, ${image2}:${tag} is empty" >&2
        done
        for tag in $(echo "${diff_raw}" | grep -E '^\+' || :); do
            tag="${tag#+}"
            echo "${SELF}: UNSYNC: ${image1}:${tag} and ${image2}:${tag} are not in synchronized, ${image1}:${tag} is empty" >&2
        done
        echo "$(echo "${diff_raw}" | grep -E '^ ' | tr -d ' ' || :)"
        return 1
    fi
    echo "${SELF}: SYNC-TAGS: ${image1} and ${image2} are in synchronized" >&2
    echo "${tags1}"
    return 0
}

function main() {
    local image1="${1:-}"
    local image2="${2:-}"

    if [[ "${image1}" =~ ":" ]]; then
        diff-image-with-tag "${image1}" "${image2}" >/dev/null || return $?
        return 0
    fi

    local list=$(diff-image "${image1}" "${image2}")

    local unsync=()
    for tag in ${list}; do
        diff-image-with-tag "${image1}:${tag}" "${image2}:${tag}" >/dev/null || unsync+=("${tag}")
    done

    if [[ "${#unsync[@]}" -gt 0 ]]; then
        echo "${SELF}: INFO: ${image1} and ${image2} are not in synchronized, there are unsynchronized tags ${#unsync[@]}: ${unsync[*]}" >&2
        return 1
    fi
}

check "${IMAGE1}" "${IMAGE2}"
main "${IMAGE1}" "${IMAGE2}"
