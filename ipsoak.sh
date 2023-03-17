#!/usr/bin/env bash

set -euo pipefail

show_help() {
    cat <<'EOF'
USAGE:
    ipsoak [OPTIONS]  [--] [FILE]...

EXAMPLES:
    ipsoak --source data.txt
    ipsoak -s "192.168.1.1/24,10.10.10.25,2404:6800:4008:c02::8b" -m ipv4
    ipsoak --geo -s https://example.com/log.txt

OPTIONS:
    -s, --source                      Choose the source data to extract ips from
    -m  --mode <type>                 Choose the mode of extraction (ipv4,ipv6,both)
    -h  --help                        Print help information
        --geo                         Geolocate all the matches
EOF
}

data_source_is_empty() {
    echo -e "You need to provide a valid source of data (file, text or url). Example: ipsoak -s log.dat"
    exit 1;
}

extract_ipv4_from_source() {
    local source=$1
}

extract_ipv6_from_source() {
    local source=$1
}


## Check if no arguments are provided to the script
if [ "$#" -eq 0 ]; then
    data_source_is_empty
fi

set_mode() {
    declare -a available_modes=("ipv4" "ipv6" "both")
    declare -i valid_mode=0
    local selected_mode=$1

    for mode in "${available_modes[@]}"; do
        if [ "$mode" = "$selected_mode" ]; then
            MODE=$mode
            valid_mode=1
            break
        fi
    done

    if [ $valid_mode -eq 0 ]; then
        echo -e "The selected mode $selected_mode is invalid, allowed values are: ${available_modes[*]}. The default mode $MODE will be used instead"
    fi
}

DATA_SOURCE=''
MODE='ipv4'
GEOLOCATION=0

for arg in "$@"; do
shift
    case "$arg" in
        '--geo')      set -- "$@" '-g'   ;;
        '--source')      set -- "$@" '-s'   ;;
        '--mode')      set -- "$@" '-g'   ;;
        '--help')      set -- "$@" '-h'   ;;
        *)             set -- "$@" "$arg" ;;
    esac
done

while getopts ":s:m:gh:" arg; do
    case $arg in
        s) DATA_SOURCE=$OPTARG;;
        m) set_mode "$OPTARG";;
        g) GEOLOCATION=1;;
        h | *)
            show_help
        ;;
    esac
done
shift $(( OPTIND - 1))

[[ -z $DATA_SOURCE ]] && data_source_is_empty