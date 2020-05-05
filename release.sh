#!/bin/sh

set -Ceu
cd -P -- "$(dirname -- "$0")"

exec zip -r bve-random-map-release.zip README.md Scenarios/magicant*
