#!/usr/bin/env bash

function filter_docker_library() {
    while read -r line; do
        if [[ $line =~ ^docker\.io/[^/]*$ ]]; then
            echo "docker.io/library/${line#docker.io/}"
        else
            echo "${line}"
        fi
    done
}

function filter_k8s_old() {
    while read -r line; do
        if [[ $line =~ ^k8s\.gcr\.io/.*$ ]]; then
            echo "registry.k8s.io/${line#k8s.gcr.io/}"
        else
            echo "${line}"
        fi
    done
}

cat $1 |
    filter_docker_library |
    filter_k8s_old >$1.tmp && mv $1.tmp $1
