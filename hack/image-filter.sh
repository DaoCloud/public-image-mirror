#!/usr/bin/env bash

SITE="https://github.com/DaoCloud/public-image-mirror"
URL_PREFIX="https://raw.githubusercontent.com/DaoCloud/public-image-mirror/main"
DOMAIN_SUFFIX="m.daocloud.io"
TMPDIR="${TMPDIR:-/tmp}/public-image-mirror"

# show the usage if arguments are provided
function usage() {
    echo "Usage: $0"
    echo "  cat <resource-file.yaml> | $0 | kubectl apply -f -"
    echo "  kubectl kustomize <kustomize-dir> | $0 | kubectl apply -f -"
    echo
    echo "For more information, please visit ${SITE}"
}

if [[ $# -ne 0 ]]; then
    usage >&2
    exit 1
fi

# output the log to stderr
function log() {
    local message="${*}"
    echo "# $0: ${message}" >&2
}

# check the command exists
function command_exists() {
    local cmd="$1"
    type "${cmd}" >/dev/null 2>&1
}

mkdir -p "${TMPDIR}"

# fetch the file or download the file if it does not exist
function fetch() {
    local file="${1}"

    # check local directory first
    if [[ -f "${file}" ]]; then
        cat "${file}"
        return 0
    fi

    # check the cache directory
    if [[ -s "${TMPDIR}/${file}" ]]; then
        cat "${TMPDIR}/${file}"
        return 0
    fi

    # download the file
    local url="${2}"
    log "Fetching ${file} from ${url} cache to ${TMPDIR}"
    if command_exists wget; then
        log wget "${url}" -c -O "${TMPDIR}/${file}"
        wget "${url}" -c -O "${TMPDIR}/${file}" >&2
        cat "${TMPDIR}/${file}"
    elif command_exists curl; then
        log curl "${url}" -L -o "${TMPDIR}/${file}"
        curl "${url}" -L -o "${TMPDIR}/${file}" >&2
        cat "${TMPDIR}/${file}"
    else
        log "Please install wget or curl to download the file and retry"
        log "Or you can manually download the file ${url} and put it to ${TMPDIR}/${file}"
        exit 1
    fi
}

# take the first column
function first_column() {
    cat | grep -v '^#' | awk '{print $1}'
}

DOMAIN_LIST="$(fetch "domain.txt" "${URL_PREFIX}/domain.txt" | first_column)"
MIRROR_LIST="$(fetch "mirror.txt" "${URL_PREFIX}/mirror.txt" | first_column)"
EXCLUDE_LIST="$(fetch "exclude.txt" "${URL_PREFIX}/exclude.txt" | first_column)"

# check the tag are excluded
function is_exclude() {
    local tag="${1}"
    for exclude in ${EXCLUDE_LIST}; do
        if [[ "${tag}" =~ ${exclude} ]]; then
            return 0
        fi
    done
    return 1
}

# check the image is mirrored
function is_mirror() {
    local name="${1}"
    for mirror in ${MIRROR_LIST}; do
        if [[ "${name}" == "${mirror}" ]]; then
            return 0
        fi
    done
    return 1
}

# replace the prefix of the image
function replace_image() {
    local name="${1}"
    for domain in ${DOMAIN_LIST}; do
        old_prefix="${domain%%=*}"
        new_prefix="${domain#*=}"
        if [[ "${name}" =~ ^"${old_prefix}" ]]; then
            echo "${name}" | sed "s#${old_prefix}#${new_prefix}#"
            return
        fi
    done
    echo "${name}"
}

# completion the docker.io prefix
function completion_for_docker_io() {
    local name="${1}"
    if [[ "${name}" =~ "." ]]; then
        echo "${name}"
    else
        echo "docker.io/${name}"
    fi
}

# replace image prefix on the line
function replace_line() {
    local line="${1}"

    # get the image full name
    local raw_image="$(echo "${line#*: }" | awk '{print $1}' | sed 's/"//g' | sed "s/'//g")"
    local image="${raw_image}"
    local image_name=""
    local image_tag=""

    # remove the sha256 suffix
    if [[ "${image}" =~ "@" ]]; then
        image="${image%%@*}"
    fi

    # split the image name and tag
    if [[ "${image}" =~ ":" ]]; then
        image_tag="${image#*:}"
        image_name="${image%%:*}"
    else
        image_name="${image}"
    fi

    # check the image is replaced
    if [[ "${image_name}" =~ "${DOMAIN_SUFFIX}" ]]; then
        return 1
    fi

    # completion the docker.io prefix
    image_name="$(completion_for_docker_io "${image_name}")"

    # check the image is mirrored
    if ! is_mirror "${image_name}"; then
        log "Image '${image}' is not synchronized yet, if you want please send a PR to add it on ${SITE}"
        return 1
    fi

    # check the tag is empty
    if [[ "${image_tag}" == "" ]]; then
        log "Image '${image}' must have a tag"
        return 1
    fi

    # check the tag is excluded
    if is_exclude "${image_tag}"; then
        log "Image '${image}' tag excludes out of synchronize"
        return 1
    fi

    # replace the prefix of the image
    local new_image="$(replace_image "${image_name}"):${image_tag}"
    local new_line=$(echo "${line}" | sed "s|${raw_image}|${new_image}|")

    log "Replace '${raw_image}' with '${new_image}'"

    echo "${new_line}"
}

function main() {
    local new_line
    cat | while read line; do
        if [[ "${line}" =~ "image: " || "${line}" =~ "image': " || "${line}" =~ 'image": ' ]]; then
            new_line="$(replace_line "${line}")"
            if [[ $? -eq 0 ]]; then
                echo "${new_line}"
            else
                echo "${line}"
            fi
        else
            echo "${line}"
        fi
    done
}

IFS=$'\n'

main
