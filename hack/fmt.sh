#!/usr/bin/env bash

export LC_ALL=C

cat $1 | sort -u | grep -v '^$' > $1.tmp && mv $1.tmp $1
