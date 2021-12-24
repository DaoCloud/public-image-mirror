#!/usr/bin/env bash

if [[ "${#}" -ne 0 && "$1" != "-" ]]; then
    tmp=$(cat "${1}")
else
    tmp=$(cat)
fi

domains=(
    cr.l5d.io
    docker.elastic.co
    docker.io
    gcr.io
    ghcr.io
    k8s.gcr.io
    mcr.microsoft.com
    nvcr.io
    quay.io
    registry.jujucharms.com
    rocks.canonical.com
)

SUFFIX=${SUFFIX:-"m.daocloud.io"}

function replace_domain() {
    local domain="${1}"
    IFS='.' read -ra arr <<<"${domain}"
    local len=${#arr[@]}
    if [[ "${len}" -eq 2 ]]; then
        echo "${arr[0]}.${SUFFIX}"
        return 0
    fi

    if [[ "${arr[0]}" == "registry" ]]; then
        echo "${arr[1]}.${SUFFIX}"
        return 0
    fi
    if [[ "${arr[0]}" == "docker" ]]; then
        echo "${arr[1]}.${SUFFIX}"
        return 0
    fi
    if [[ "${arr[0]}" == "cr" ]]; then
        echo "${arr[1]}.${SUFFIX}"
        return 0
    fi

    if [[ "${arr[0]}" =~ cr$ ]]; then
        echo "${arr[0]}.${SUFFIX}"
        return 0
    fi

    unset 'arr[${#arr[@]}-1]'

    IFS='-'
    echo "${arr[*]}.${SUFFIX}"

    unset IFS
    return 0
}

function replace_all() {
    tmp="${1}"
    for line in ${domains[*]}; do
        key="${line}"
        val="$(replace_domain ${line})"
        if [[ "${key}" == "" || "${val}" == "" ]]; then
            continue
        fi
        tmp="$(echo "${tmp}" | sed -e "s# ${key}# ${val}#g")"
    done

    # Remove sha256 hash
    tmp="$(echo "${tmp}" | sed -e "s#@sha256:[0-9a-f]\{64\}##g")"
    echo "${tmp}"
}


replace_all "${tmp}"
