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

extract_ipv4_from_source() {
    local source=$1
}

if [ "$#" -eq 0 ]; then
    echo -e "You need to provide a valid source of data (file, text or url). Example > [ipsoak -s log.dat]"
    exit 1;
fi

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
        m) MODE=$OPTARG;;
        g) GEOLOCATION=1;;
        h | *)
            show_help
        ;;
    esac

done
shift $(( OPTIND - 1))

echo "$DATA_SOURCE, $MODE, $GEOLOCATION"