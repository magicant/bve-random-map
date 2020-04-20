#!/bin/bash

set -eu
cd -P -- "$(dirname -- "$0")"

for file in stations_*h_*.csv
do
    pretraintime=${file#stations_}
    pretraintime=${pretraintime%h*}00

    IFS=,
    words=($(grep station_0 "$file"))
    starttime=${words[5]//:/}

    if [ "$pretraintime" -gt "$starttime" ]
    then
        printf '%s: wrong time\n' "$file" >&2
        exit 1
    fi
done

# vim: set et sw=4:
