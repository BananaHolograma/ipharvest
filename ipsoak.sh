#!/usr/bin/env bash

set -euo pipefail

show_help() {
    cat <<'EOF'
USAGE:
    ipsoak [OPTIONS]  [--] [FILE]...

EXAMPLES:
    ipsoak --source data.txt
    ipsoak -s "192.168.1.1/24,10.10.10.25,2404:6800:4008:c02::8b" -m ipv6
    ipsoak --geo -s https://example.com/log.txt

OPTIONS:
    -s, --source                      Choose the source data to extract ips from
    -m  --mode <type>                 Choose the mode of extraction (ipv4,ipv6,both)
    -h  --help                        Print help information
        --geo                         Geolocate all the ip matches
EOF
}

data_source_is_empty() {
    echo -e "You need to provide a valid source of data (file, text or url). Example: ipsoak -s log.dat"
    exit 1;
}

to_lowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

is_url() {
    local url=$1
    regex='(https?|ftp|file)://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]'

    [[ $url =~ $regex ]]
}

extract_ipv4_from_source() {
    local source=$1
    local source_type=$2
}

extract_ipv6_from_source() {
    local source=$1
    local source_type=$2
}

set_mode() {
    declare -a available_modes=("ipv4" "ipv6" "both")
    declare -i valid_mode=0
    local selected_mode
    selected_mode=$(to_lowercase "$1")

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

set_data_source() {
    local source=$1

    [[ -z $source ]] && data_source_is_empty

    if [ -f "$source" ]; then
        DATA_SOURCE=$source
        DATA_SOURCE_TYPE='file'
    fi 
    
    if is_url "$source"; then 
        DATA_SOURCE=$source
        DATA_SOURCE_TYPE='url'
   fi
}

## Check if no arguments are provided to the script
if [ "$#" -eq 0 ]; then
    data_source_is_empty
fi

DATA_SOURCE=''
DATA_SOURCE_TYPE='text'
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
        s) set_data_source "$OPTARG";;
        m) set_mode "$OPTARG";;
        g) GEOLOCATION=1;;
        h | *)
            show_help
        ;;
    esac
done
shift $(( OPTIND - 1))

if [ "$MODE" = 'ipv4' ]; then
    extract_ipv4_from_source "$DATA_SOURCE" "$DATA_SOURCE_TYPE"
elif [ "$MODE" = 'ipv6' ]; then 
    extract_ipv6_from_source "$DATA_SOURCE" "$DATA_SOURCE_TYPE"
else 
    extract_ipv4_from_source "$DATA_SOURCE" "$DATA_SOURCE_TYPE"
    extract_ipv6_from_source "$DATA_SOURCE" "$DATA_SOURCE_TYPE"
fi 