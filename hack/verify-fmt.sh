#!/usr/bin/env bash

export LC_ALL=C

cp $1 $1.bak

$(dirname "${BASH_SOURCE}")/fmt.sh $1.bak

diff -c $1 $1.bak && rm $1.bak
