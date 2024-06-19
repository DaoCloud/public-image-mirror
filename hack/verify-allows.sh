#!/usr/bin/env bash

file=$1

image=$2

function check_allows() {
    local file=$1
    local image=$2
    while read line; do
        if [[ "${line}" == *"**" ]]; then
            if [[ "${image}" == "${line%\*\*}"* ]]; then
                return 0
            fi
        elif [[ "${line}" == *"*" ]]; then
            if [[ "${image}" == "${line%\*}"* ]]; then
                if [[ "${image#"${line%\*}"}" != *"/"* ]]; then
                    return 0
                fi
            fi
        elif [[ "${line}" == "${image%\:*}" ]]; then
            return 0
        fi
    done <"${file}"

    return 1
}

check_allows "${file}" "${image}"
