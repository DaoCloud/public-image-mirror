#!/usr/bin/env bash

export LC_ALL=C

cat $1 |
    filter_docker_library |
    filter_k8s_old |
    sort -u |
    grep -v '^$' >$1.tmp && mv $1.tmp $1
