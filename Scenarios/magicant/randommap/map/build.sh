#!/bin/bash

security_types=(csatc snp swp2)
files_per_security=5
stations_per_file=13 # including the first and last stations
station_rate=29490 # < 32768
terminal_rate=16384 # <= 32768

set -eu
cd -P -- "$(dirname -- "$0")"
IFS=$' \t\n\r'

# $candidate_part_file = name of the candidate part file
candidate_is_dummy() {
    grep -q '^//DUMMY' "$candidate_part_file"
}

# $candidate_part_file = name of the candidate part file
candidate_is_station() {
    grep -q '^//STATION' "$candidate_part_file"
}

# $candidate_part_file = name of the candidate part file
candidate_is_terminal() {
    grep -q '^//TERMINAL' "$candidate_part_file"
}

# $candidate_part_file [in-out] = name of the candidate part file
next_candidate_part() {
    candidates=($(
        sed -n 's|^//FOLLOWS:[[:space:]]*||p' "$candidate_part_file"
    ))
    if [ "${#candidates[@]}" -le 0 ]
    then
        printf 'Error: Part file "%s" has no preceding part\n' "$candidate_part_file" >&2
        return 1
    fi
    candidate_part_file=${candidates[$((RANDOM % ${#candidates[@]}))]}
}

# $current_part_file [in] = name of the previous part file
# $candidate_part_file [out] = name of the next part file candidate
next_non_dummy_candidate_part() {
    candidate_part_file=$current_part_file
    next_candidate_part
    while candidate_is_dummy
    do
        next_candidate_part
    done
}

# $candidate_part_file = name of the candidate part file
# $next_part_type = type of the next part
candidate_is_applicable() {
    case "$next_part_type" in
        (station)
            candidate_is_station
            ;;
        (terminal)
            candidate_is_terminal
            ;;
        (*)
            ! candidate_is_station
            ;;
    esac
}

# $non_station_probability [in-out] = [0,32768]
# $current_part_file [in-out] = name of the previous part file
# $station_count [in-out] = number of stations generated so far
next_part() {
    if [ "$RANDOM" -ge "$non_station_probability" ]
    then
        next_part_type=station
    else
        next_part_type=non-station
    fi

    next_non_dummy_candidate_part
    until candidate_is_applicable
    do
        next_non_dummy_candidate_part
    done
    current_part_file=$candidate_part_file

    printf "include '%s';\r\n" "$current_part_file"

    case "$next_part_type" in
        (station|terminal)
            station_count=$((station_count+1))
            non_station_probability=32768
            ;;
        (*)
            non_station_probability=$((non_station_probability * station_rate / 32767))
            ;;
    esac
}

# $file_name = name of the file to build
# $security = one of the security types
build_file() {
    printf 'BveTs Map 2.02\r\n\r\n'
    printf "include '%s';\r\n\r\n" "../map_misc/init_${security}.txt"

    current_part_file="../map_parts/last.txt"
    station_count=0

    if [ "$RANDOM" -ge "$terminal_rate" ]
    then
        # start with some non-station parts
        non_station_probability=55491
    else
        # start with a terminal station
        non_station_probability=0
    fi

    until [ "$station_count" -ge "$stations_per_file" ]
    do
        next_part
    done

    printf "\r\ninclude '%s';\r\n" "../map_misc/fin_${security}.txt"
} >"$file_name"

for security in "${security_types[@]}"
do
    file_number=0
    printf 'Route = '
    while [ "$file_number" -lt "$files_per_security" ]
    do
        file_name="${security}_${file_number}.txt"
        build_file
        if [ "$file_number" -gt 0 ]
        then
            printf ' | '
        fi
        printf 'magicant\\randommap\\map\\%s' "$file_name"
        file_number=$((file_number+1))
    done
    printf '\r\n'
done

# vim: set et sw=4:
