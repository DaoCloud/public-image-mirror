#!/usr/bin/env bash

cat $1  | grep NOT-SYNCHRONIZED | awk '{print $3}' | grep ':' | tr ':' ' ' | awk '{print $1}' | uniq -c | sort -nrk 1
