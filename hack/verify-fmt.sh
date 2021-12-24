#!/usr/bin/env bash

cp $1 $1.bak
./hack/fmt.sh $1

diff -c $1 $1.bak
rm $1.bak
