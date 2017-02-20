#!/bin/bash

i=1
for p in "$@"; do
    echo Argument $i: ${!i}
    i=$((i+1))
done
