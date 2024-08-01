#!/usr/bin/env bash

function check_match() {
    local image=$1
    local lines=$2
    for line in ${lines}; do
        if [[ "${line}" == *"/**" ]]; then
            if [[ "${image}" == "${line%\*\*}"* ]]; then
                return
            fi
        elif [[ "${line}" == *"/*" ]]; then
            if [[ "${image}" == "${line%\*}"* ]]; then
                if [[ "${image#"${line%\*}"}" != *"/"* ]]; then
                    return
                fi
            fi
        fi
    done

    echo "${image}"
}

function check_match_more() {
    local image=$1
    local lines=$2
    for line in ${lines}; do
        if [[ "${line}" == *"/**" ]]; then
            if [[ "${image}" == "${line%\*\*}"* ]]; then
                return
            fi
        fi
    done

    echo "${image}"
}

function format() {
    local file=$1
    local lines="$(cat "${file}")"
    for line in ${lines}; do
        if [[ "${line}" != *"*" ]]; then
            check_match  "${line}" "${lines}"
        fi
    done

    for line in ${lines}; do
        if [[ "${line}" == *"/**" ]]; then
            echo "${line}"
        elif [[ "${line}" == *"/*" ]]; then
            check_match_more  "${line}" "${lines}"
        fi
    done
}

export LC_ALL=C
file=$1

format "${file}" |
    sort -u |
    grep -v '^$' >$1.tmp && mv $1.tmp $1
