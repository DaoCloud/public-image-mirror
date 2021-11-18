#!/usr/bin/env bash

cat $1 | sort | tac > $1.tmp && mv $1.tmp $1
