#!/usr/bin/env bash

CURRENT_DIR=$(dirname -- "$(readlink -f -- "$BASH_SOURCE")")

shc -f "$CURRENT_DIR/../ipharvest.sh" -o "$CURRENT_DIR/../bin/ipharvest"

rm "$CURRENT_DIR/../ipharvest.sh.x.c" 2>/dev/null