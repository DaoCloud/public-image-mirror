#!/usr/bin/env bash

file=mirror.txt

cp ${file} ${file}.bak

cat ${file} | grep docker.io | grep library | sed 's#docker.io/library/#docker.io/#' >>${file}.bak

cat ${file} | grep -e "docker\.io/\w\+:\|docker\.io/\w\+$" | sed 's#docker.io/#docker.io/library/#' >>${file}.bak

$(dirname "${BASH_SOURCE}")/fmt.sh ${file}.bak

result=$(diff ${file} ${file}.bak)

if [[ "${result}" != "" ]]; then
    echo "Usually docker.io/* and docker.io/library/* appear in pairs "
    echo "Please run following command to fix the issue:"
    echo "cat <<EOF >> ${file}"
    echo "${result}" | grep "^>" | sed 's/^>\s\+//'
    echo "EOF"
    echo "./hack/fmt.sh ${file}"

    exit 1
fi

rm ${file}.bak
