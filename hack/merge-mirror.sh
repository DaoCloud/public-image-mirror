#!/usr/bin/env bash

base_list="${1}"
used_list="${2}"
used_top="${3:-100}"

function used_top() {
    cat "${used_list}" | head -n "${used_top}"
}

function intersection_used() {
    sort "${base_list}" "${used_list}" | uniq -d
}

function fixed_docker() {
    grep "^docker\.io/library/" "${base_list}"
    grep "^docker\.io/library/" "${used_list}"
}

function fixed_k8s() {
    grep "^registry\.k8s\.io/" "${base_list}"
    grep "^registry\.k8s\.io/" "${used_list}"
}

function fixed_istio() {
    grep "^docker\.io/istio/" "${base_list}"
    grep "^docker\.io/istio/" "${used_list}"
}

cat <(used_top) \
    <(intersection_used) \
    <(fixed_docker) \
    <(fixed_k8s) | sort | uniq -u
