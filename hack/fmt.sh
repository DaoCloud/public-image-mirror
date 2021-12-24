#!/usr/bin/env bash

cat $1 | sort -u | grep -v '^$' > $1.tmp && mv $1.tmp $1
