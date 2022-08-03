#!/usr/bin/env bash

file=$1

cp ${file} ${file}.bak

cat ${file} | grep k8s.gcr.io/ | sed 's#k8s.gcr.io/#registry.k8s.io/#' >>${file}.bak

$(dirname "${BASH_SOURCE}")/fmt.sh ${file}.bak

result=$(diff ${file} ${file}.bak)

if [[ "${result}" != "" ]]; then
    echo "Usually registry.k8s.io/* instead of k8s.gcr.io/*"
    echo "Please run following command to fix the issue:"
    echo "cat ${file} | sed 's#k8s.gcr.io/#registry.k8s.io/#' >${file}.bak"
    echo "mv ${file}.bak ${file}"
    echo "./hack/fmt.sh ${file}"

    exit 1
fi

rm ${file}.bak
