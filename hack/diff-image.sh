#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Output more information that is out of synchronize
DEBUG="${DEBUG:-}"

IMAGE1="${1:-}"
IMAGE2="${2:-}"

SKOPEO="${SKOPEO:-skopeo}"
JQ="${JQ:-jq}"

# Allow image2 to have more tags than image1
INCREMENTAL="${INCREMENTAL:-}"

# Compare only tags that are in both images
QUICKLY="${QUICKLY:-}"

# If set, will compare the image tag patterns
QUICKLY_PATTERN="${QUICKLY_PATTERN:-}"

# Regexp that matches the tags
FOCUS="${FOCUS:-}"

# Regexp that matches the tags that needs to be skipped
SKIP="${SKIP:-}"

# Compare the number of tags in parallel
PARALLET="${PARALLET:-0}"

# Synchronize images from source to destination
SYNC="${SYNC:-}"

# Retry times
RETRY="${RETRY:-5}"

SELF="$(basename "${BASH_SOURCE[0]}")"

if [[ "${DEBUG}" == "true" ]]; then
    echo "DEBUG:           ${DEBUG}"
    echo "IMAGE1:          ${IMAGE1}"
    echo "IMAGE2:          ${IMAGE2}"
    echo "SKOPEO:          ${SKOPEO}"
    echo "JQ:              ${JQ}"
    echo "INCREMENTAL:     ${INCREMENTAL}"
    echo "QUICKLY:         ${QUICKLY}"
    echo "QUICKLY_PATTERN: ${QUICKLY_PATTERN}"
    echo "FOCUS:           ${FOCUS}"
    echo "SKIP:            ${SKIP}"
    echo "PARALLET:        ${PARALLET}"
    echo "SYNC:            ${SYNC}"
    echo "RETRY:           ${RETRY}"
fi

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
        echo " DEBUG=true                # Output more information that is out of synchronize"
        echo " INCREMENTAL=true          # Allow image2 to have more tags than image1"
        echo " QUICKLY=true              # Compare only tags that are in both images"
        echo " QUICKLY_PATTERN=<pattern> # Regexp that matches the tags"
        echo " FOCUS=<pattern>           # Regexp that matches the tags"
        echo " SKIP=<pattern>            # Regexp that matches the tags that needs to be skipped"
        echo " PARALLET=<size>           # Compare the number of tags in parallel"
        echo " SYNC=true                 # Synchronize images from source to destination"
        echo " RETRY=<times>             # Retry times"
        return 2
    fi

    if [[ "${image1#*/}" =~ ":" ]]; then
        if [[ "${image2#*/}" =~ ":" ]]; then
            return 0
        else
            echo "${SELF}: ERROR: ${image1} and ${image2} must both be full images or not be tag references" >&2
            return 2
        fi
    else
        if [[ "${image2#*/}" =~ ":" ]]; then
            echo "${SELF}: ERROR: ${image1} and ${image2} must both be full images or not be tag references" >&2
            return 2
        else
            return 0
        fi
    fi
}

emptyLayer="sha256:a3ed95caeb02ffe68cdd9fd84406680ae93d633cb16422d00e8a7c22955b46d4"

function inspect() {
    local image="${1:-}"
    local raw=$(${SKOPEO} inspect --retry-times "${RETRY}" --raw --tls-verify=false "docker://${image}")
    if [[ "${raw}" == "" ]]; then
        echo "skopeo inspect --retry-times "${RETRY}" --raw --tls-verify=false docker://${image}" >&2
        echo "ERROR: Failed to inspect ${image}" >&2
        return 1
    fi

    local schemaVersion=$(echo "${raw}" | ${JQ} -r '.schemaVersion')
    case "${schemaVersion}" in
    1)
        echo "${raw}" | ${JQ} -r '.fsLayers[].blobSum' | grep -v "${emptyLayer}" | tac
        ;;
    2)
        local mediaType=$(echo "${raw}" | ${JQ} -r '.mediaType // "" ')
        if [[ "${mediaType}" == "" ]]; then
            if [[ "$(echo "${raw}" | ${JQ} -r '.layers | length')" -gt 0 ]]; then
                mediaType="layers"
            elif [[ "$(echo "${raw}" | ${JQ} -r '.manifests | length')" -gt 0 ]]; then
                mediaType="manifests"
            fi
        fi

        case "${mediaType}" in
        "layers" | "application/vnd.docker.distribution.manifest.v2+json")
            echo "${raw}" | ${JQ} -r '.layers[].digest' | grep -v "${emptyLayer}"
            ;;
        "manifests" | "application/vnd.docker.distribution.manifest.list.v2+json")
            local line=$(echo "${raw}" | ${JQ} -j '.manifests[] | .platform.architecture , " " , .platform.os , "\n"' | sort)
            IFS=$'\n'
            for args in ${line}; do
                local arch="${args%% *}"
                local os="${args##* }"
                echo ${args}
                ${SKOPEO} --override-arch "${arch}" --override-os "${os}" inspect --retry-times "${RETRY}" --config --tls-verify=false "docker://${image}" | jq -r '.rootfs.diff_ids[]'
            done
            unset IFS
            ;;
        *)
            echo "skopeo inspect --retry-times "${RETRY}" --raw --tls-verify=false docker://${image}" >&2
            if [[ "${DEBUG}" == "true" ]]; then
                echo "${raw}" >&2
            fi
            echo "${SELF}: ERROR: Unknown media type: ${mediaType}" >&2
            return 2
            ;;
        esac
        ;;
    *)
        echo "skopeo inspect --retry-times "${RETRY}" --raw --tls-verify=false docker://${image}" >&2
        if [[ "${DEBUG}" == "true" ]]; then
            echo "${raw}" >&2
        fi
        echo "${SELF}: ERROR: Unknown schema version: ${schemaVersion}" >&2
        return 2
        ;;
    esac
}

function copy-image() {
    local image1="${1:-}"
    local image2="${2:-}"

    ${SKOPEO} copy --retry-times "${RETRY}" --all --dest-tls-verify=false "docker://${image1}" "docker://${image2}"
}

function list-tags() {
    local image="${1:-}"
    local raw="$(${SKOPEO} list-tags --retry-times "${RETRY}" --tls-verify=false "docker://${image}" | ${JQ} -r '.Tags[]')"

    # Sort by string length
    raw=$(echo "${raw}" | awk '{print length, $0}' | sort -n | awk '{print $2}')

    if [[ "${FOCUS}" != "" ]]; then
        local skip=$(echo "${raw}" | grep -v -E "${FOCUS}")
        if [[ "${skip}" != "" ]]; then
            echo "${SELF}: SKIP: ${image} with focus: ${FOCUS}:" ${skip} >&2
        fi
        raw="$(echo "${raw}" | grep -E "${FOCUS}" || :)"
    fi

    if [[ "${SKIP}" != "" ]]; then
        local skip=$(echo "${raw}" | grep -E "${SKIP}")
        if [[ "${skip}" != "" ]]; then
            echo "${SELF}: SKIP: ${image} with skip: ${SKIP}:" ${skip} >&2
        fi
        raw="$(echo "${raw}" | grep -v -E "${SKIP}" || :)"
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
            echo "${SELF}: NOT-SYNCHRONIZED: ${image1} and ${image2} are not in synchronized" >&2
            return 1
        fi
         
        if [[ "${QUICKLY_PATTERN}" == "" || ("${QUICKLY_PATTERN}" != "" && "${tag1}" =~ ${QUICKLY_PATTERN}) ]]; then
            echo "${SELF}: SYNCHRONIZED: ${image1} and ${image2} are in synchronized" >&2
            return 0
        fi
    fi

    local inspect2="$(inspect ${image2})"
    if [[ "${inspect2}" == "" ]]; then
        echo "${SELF}: NOT-SYNCHRONIZED: ${image1} and ${image2} are not in synchronized, ${image2} content is empty" >&2
        return 1
    fi

    local inspect1="$(inspect ${image1})"
    local diff_raw=$(diff --unified <(echo "${inspect1}") <(echo "${inspect2}"))

    if [[ "${diff_raw}" != "" ]]; then
        echo "${SELF}: NOT-SYNCHRONIZED: ${image1} and ${image2} are not in synchronized" >&2
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
    echo "${SELF}: SYNCHRONIZED: ${image1} and ${image2} are in synchronized" >&2
}

function diff-image() {
    local image1="${1:-}"
    local image2="${2:-}"

    local tags1="$(list-tags ${image1})"
    local tags2="$(list-tags ${image2})"
    local diff_raw="$(diff --unified <(echo "${tags1}") <(echo "${tags2}") | grep -v -E '^---' | grep -v -E '^\+\+\+' || :)"
    local increase="$(echo "${diff_raw}" | grep -E '^\+' | sed 's/^\+//' || :)"
    local reduce="$(echo "${diff_raw}" | grep -E '^-' | sed 's/^-//' || :)"
    local common="${tags1}"

    if [[ "${increase}" != "" ]]; then
        common="$(echo "${common}" | grep -v -f <(echo "${increase}") || :)"
    fi

    if [[ "${reduce}" != "" ]]; then
        common="$(echo "${common}" | grep -v -f <(echo "${reduce}") || :)"
    fi

    if [[ "${INCREMENTAL}" == "true" ]]; then
        increase=""
    fi

    if [[ "${QUICKLY}" == "" ]] || [[ "${reduce}" != "" ]] || [[ "${increase}" != "" ]]; then
        echo "${SELF}: NOT-SYNCHRONIZED-TAGS: ${image1} and ${image2} are not in synchronized" >&2
        if [[ "${DEBUG}" == "true" ]]; then
            echo "DEBUG: image1 ${image1}:" >&2
            echo "${tags1}" >&2
            echo "DEBUG: image2 ${image2}:" >&2
            echo "${tags2}" >&2
            echo "DEBUG: diff:" >&2
            echo "${diff_raw}" >&2
        fi
        for tag in ${reduce}; do
            echo "${SELF}: NOT-SYNCHRONIZED: ${image1}:${tag} and ${image2}:${tag} are not in synchronized, ${image2}:${tag} does not exist" >&2
            if [[ "${SYNC}" == "true" ]]; then
                echo "${SELF}: SYNCHRONIZE: synchronize from ${image1}:${tag} to ${image2}:${tag}" >&2
                copy-image "${image1}:${tag}" "${image2}:${tag}" >&2
            fi
        done
        for tag in ${increase}; do
            echo "${SELF}: NOT-SYNCHRONIZED: ${image1}:${tag} and ${image2}:${tag} are not in synchronized, ${image1}:${tag} does not exist" >&2
        done
        echo "${common}"
        return 1
    fi
    echo "${SELF}: SYNCHRONIZED-TAGS: ${image1} and ${image2} are in synchronized" >&2
    echo "${common}"
    return 0
}

function wait_jobs() {
    local job_num=${1:-3}
    local perc=$(jobs -p | wc -l)
    while [ "${perc}" -gt "${job_num}" ]; do
        sleep 1
        perc=$(jobs -p | wc -l)
    done
}

function main() {
    local image1="${1:-}"
    local image2="${2:-}"

    if [[ "${image1#*/}" =~ ":" ]]; then
        if [[ "${SYNC}" == "true" ]]; then
            echo "${SELF}: SYNCHRONIZE: synchronize from ${image1} to ${image2}" >&2
            copy-image "${image1}" "${image2}"
            return $?
        fi
        diff-image-with-tag "${image1}" "${image2}" >/dev/null
        return $?
    fi

    local list=$(diff-image "${image1}" "${image2}")

    local notsynced=()
    if [[ "${PARALLET}" -eq 0 ]]; then
        for tag in ${list}; do
            diff-image-with-tag "${image1}:${tag}" "${image2}:${tag}" >/dev/null || {
                if [[ "${SYNC}" == "true" ]]; then
                    echo "${SELF}: SYNCHRONIZE: synchronize from ${image1}:${tag} to ${image2}:${tag}" >&2
                    copy-image "${image1}:${tag}" "${image2}:${tag}"
                fi
                notsynced+=("${tag}")
            }
        done
    else
        for tag in ${list}; do
            wait_jobs "${PARALLET}"
            diff-image-with-tag "${image1}:${tag}" "${image2}:${tag}" >/dev/null || {
                if [[ "${SYNC}" == "true" ]]; then
                    echo "${SELF}: SYNCHRONIZE: synchronize from ${image1}:${tag} to ${image2}:${tag}" >&2
                    copy-image "${image1}:${tag}" "${image2}:${tag}"
                fi
                notsynced+=("${tag}")
            } &
        done
        wait
    fi

    if [[ "${#notsynced[@]}" -gt 0 ]]; then
        echo "${SELF}: INFO: ${image1} and ${image2} are not in synchronized, there are not synchronized tags ${#notsynced[@]}: ${notsynced[*]}" >&2
        return 1
    fi
}

check "${IMAGE1}" "${IMAGE2}"
main "${IMAGE1}" "${IMAGE2}"
