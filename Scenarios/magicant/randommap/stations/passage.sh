#!/bin/bash

station_count=13

set -eu
cd -P -- "$(dirname -- "$0")"

filename=${1:?Target file not specified}
timestr=${filename#stations_}
timestr=${timestr%%h*}
hour=$((timestr / 100))
minute=$((timestr % 100))
time=$((hour * 60 + minute))
is_express=$((time / 7 % 2))
random=$((time * 31 / 5))

mv "${filename}" "${filename}.bak"
exec <"${filename}.bak" >"${filename}"

IFS=,

read -r line
printf '%s\n' "$line"
read -r line
printf '%s\n' "$line"

read -r station_key station_name arrival_time remainder
if [ "$arrival_time" = p ]; then
    arrival_time= # Don't pass the first station
fi
printf '%s,%s,%s,%s\n' \
    "$station_key" "$station_name" "$arrival_time" "$remainder"

for ((i = 2; i < station_count; i++)); do
    random=$(((random % 255 + 1) * 31))
    read -r station_key station_name arrival_time remainder
    if ((is_express && random / 256 % 4)); then
        arrival_time=p
    elif [ "$arrival_time" ]; then
        arrival_time=
    fi
    printf '%s,%s,%s,%s\n' \
        "$station_key" "$station_name" "$arrival_time" "$remainder"
done

read -r station_key station_name arrival_time remainder
if [ "$arrival_time" = p ]; then
    arrival_time= # Don't pass the last station
fi
printf '%s,%s,%s,%s\n' \
    "$station_key" "$station_name" "$arrival_time" "$remainder"

# vim: set et sw=4:
