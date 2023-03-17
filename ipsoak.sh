#!/usr/bin/env bash

set -euo pipefail

### GLOBALS ###
IP4_REGEX='(?!0|22[4-9]|23[0-9])((\d|[1-9]\d|1\d{2}|2[0-4]\d|25[0-5])\.){3}(\d|[1-9]\d|1\d{2}|2[0-4]\d|25[0-5])'
IP6_REGEX='((?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){6}(?::[0-9a-fA-F]{1,4}){1,2}|(?:[0-9a-fA-F]{1,4}:){5}(?::[0-9a-fA-F]{1,4}){1,3}|(?:[0-9a-fA-F]{1,4}:){4}(?::[0-9a-fA-F]{1,4}){1,4}|(?:[0-9a-fA-F]{1,4}:){3}(?::[0-9a-fA-F]{1,4}){1,5}|(?:[0-9a-fA-F]{1,4}:){2}(?::[0-9a-fA-F]{1,4}){1,6}|(?:[0-9a-fA-F]{1,4}:){1}(?::[0-9a-fA-F]{1,4}){1,7}|(?::(?::[0-9a-fA-F]{1,4}){1,7}){1})(?:::[0-9a-fA-F]{1,4}[0-9a-fA-F]{1,4})?'

DATA_SOURCE=''
DATA_SOURCE_TYPE='text'
MODE='both'
GEOLOCATION=0
REMOVE_DUPLICATES=0
IP4_MATCHES=''
IP6_MATCHES=''
GREP_COMMAND='grep' # GNU Linux grep command by default

if [[ $OSTYPE == 'darwin'* ]]; then 
    # In MacOS systems we need to use the ggrep command to have the same behaviour as GNU/Linux grep
    GREP_COMMAND='ggrep'
fi
### ###

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
    -u  --unique                      Remove duplicated matches      
    -h  --help                        Print help information
        --geo                         Geolocate all the ip matches
EOF
}

data_source_is_empty() {
    echo -e "You need to provide a valid source of data (file, text or url). Example: ipsoak -s log.dat"
    exit 1
}

to_lowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

is_url() {
    local url=$1
    regex='(https?|ftp|file)://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]'

    [[ $url =~ $regex ]]
}

command_exists() {
    local COMMAND=$1

    [[ -n "$(command -v "$COMMAND")" ]]
  }

extract_ipv4_from_source() {
    local source=$1
    local source_type=$2

    if [ "$source_type" = 'file' ]; then
        get_ipv4_from_file "$source"

    elif [ "$source_type" = 'text' ]; then
        get_ipv4_from_text "$source"

    elif [ "$source_type" = 'url' ]; then
        get_ipv4_from_url "$source"
       
    else  
        echo -e "[ FAILED ] We couldn't discover the data source type, aborting operation..."
        exit 1
    fi
}

extract_ipv6_from_source() {
    local source=$1
    local source_type=$2

    if [ "$source_type" = 'file' ]; then
        get_ipv6_from_file "$source"

    elif [ "$source_type" = 'text' ]; then
        get_ipv6_from_text "$source"

    elif [ "$source_type" = 'url' ]; then
        get_ipv6_from_url "$source"
    else  
        echo -e "[ FAILED ] We couldn't discover the data source type, aborting operation..."
        exit 1
    fi
}

get_ipv4_from_file() {
    local file=$1
    IP4_MATCHES=$($GREP_COMMAND  -Pohw "$IP4_REGEX" "$file")
}

get_ipv4_from_text() {
    local text=$1
    IP4_MATCHES=$(echo "$text" | $GREP_COMMAND -Pohw "$IP4_REGEX")
}

get_ipv4_from_url() {
    local url=$1

     if command_exists 'curl'; then 
        curl -ksLo downloaded_file "$url" \
            && get_ipv4_from_file downloaded_file

    elif command_exists 'wget'; then 
        wget -O download_file "$url" \
            && get_ipv4_from_file downloaded_file

    else 
        echo -e "We couldn't fetch the source from $url because commands wget and curl are not available in your system"
    fi
}

get_ipv6_from_url() {
    local url=$1

     if command_exists 'curl'; then 
        curl -ksLo downloaded_file "$url" \
            && get_ipv6_from_file downloaded_file

    elif command_exists 'wget'; then 
        wget -O download_file "$url" \
            && get_ipv6_from_file downloaded_file

    else 
        echo -e "We couldn't fetch the source from $url because commands wget and curl are not available in your system"
    fi
}

get_ipv6_from_file() {
    local file=$1
    IP6_MATCHES=$($GREP_COMMAND  -Pohw "$IP6_REGEX" "$file")
}

get_ipv6_from_text() {
    local file=$1
    IP6_MATCHES=$(echo "$DATA_SOURCE_TYPE" | $GREP_COMMAND  -Pohw "$IP6_REGEX")
}

geolocate_ip() { 
       # The user agent only needs to have this format, it does not need to be a real domain or ip
    local ip_address=$1
    local user_agent='keycdn-tools:http://10.10.10.25'
    local url="https://tools.keycdn.com/geo.json?host=$ip_address"

    if command_exists 'curl'; then 
        curl -s -H "User-Agent: $user_agent" "$url"

    elif command_exists 'wget'; then 
        wget -U "User-Agent: $user_agent" "$url"
    else 
        echo -e "We couldn't geolocate the IP $ip_address because commands wget and curl are not available in your system"
    fi    
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
        DATA_SOURCE_TYPE='file'
    fi 
    
    if is_url "$source"; then 
        DATA_SOURCE_TYPE='url'
    fi

    DATA_SOURCE=$source
}

## Check if no arguments are provided to the script
if [ "$#" -eq 0 ]; then
    data_source_is_empty
fi

for arg in "$@"; do
shift
    case "$arg" in
        '--geo')       set -- "$@" '-g'   ;;
        '--source')    set -- "$@" '-s'   ;;
        '--unique')    set -- "$@" '-u'   ;;
        '--mode')      set -- "$@" '-g'   ;;
        '--help')      set -- "$@" '-h'   ;;
        *)             set -- "$@" "$arg" ;;
    esac
done

while getopts ":s:m:ugh:" arg; do
    case $arg in
        s) set_data_source "$OPTARG";;
        m) set_mode "$OPTARG";;
        u) REMOVE_DUPLICATES=1;;
        g) GEOLOCATION=1;;
        h | *)
            show_help
        ;;
    esac
done
shift $(( OPTIND - 1))

case $MODE in 
  ipv4)
    extract_ipv4_from_source "$DATA_SOURCE" "$DATA_SOURCE_TYPE"
    ;;
  ipv6) 
    extract_ipv6_from_source "$DATA_SOURCE" "$DATA_SOURCE_TYPE"
    ;;
  both) 
    extract_ipv4_from_source "$DATA_SOURCE" "$DATA_SOURCE_TYPE"
    extract_ipv6_from_source "$DATA_SOURCE" "$DATA_SOURCE_TYPE"
    ;;
  *) 
    echo -e "The selected mode $MODE is not supported"
    exit 1
    ;; 
esac

if [ $GEOLOCATION -eq 1 ]; then 
    echo 'geo'
fi

if [ "$REMOVE_DUPLICATES" -eq 1 ]; then 
    [[ -z $IP4_MATCHES ]] \
        && IP4_MATCHES=$(echo "$IP4_MATCHES" | sort -u)

    [[ -z $IP6_MATCHES ]] \
        && IP6_MATCHES=$(echo "$IP6_MATCHES" | sort -u)
fi
