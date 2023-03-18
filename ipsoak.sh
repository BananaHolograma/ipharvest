#!/usr/bin/env bash

set -euo pipefail

### GLOBALS ###
IP4_REGEX='(?!0|22[4-9]|23[0-9])((\d|[1-9]\d|1\d{2}|2[0-4]\d|25[0-5])\.){3}(\d|[1-9]\d|1\d{2}|2[0-4]\d|25[0-5])'
IP6_REGEX='((?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){6}(?::[0-9a-fA-F]{1,4}){1,2}|(?:[0-9a-fA-F]{1,4}:){5}(?::[0-9a-fA-F]{1,4}){1,3}|(?:[0-9a-fA-F]{1,4}:){4}(?::[0-9a-fA-F]{1,4}){1,4}|(?:[0-9a-fA-F]{1,4}:){3}(?::[0-9a-fA-F]{1,4}){1,5}|(?:[0-9a-fA-F]{1,4}:){2}(?::[0-9a-fA-F]{1,4}){1,6}|(?:[0-9a-fA-F]{1,4}:){1}(?::[0-9a-fA-F]{1,4}){1,7}|(?::(?::[0-9a-fA-F]{1,4}){1,7}){1})(?:::[0-9a-fA-F]{1,4}[0-9a-fA-F]{1,4})?'

DATA_SOURCE=''
DATA_SOURCE_TYPE='text'
MODE='both'
declare -i GEOLOCATION=0
declare -A IP_GEOLOCATION_DICTIONARY=()
OUTPUT_FILE=''
IP4_MATCHES=''
IP6_MATCHES=''
GREP_COMMAND='grep' # GNU Linux grep command by default

if [[ $OSTYPE == 'darwin'* ]]; then 
    GREP_COMMAND='ggrep'
    if ! command -v "$GREP_COMMAND" >/dev/null 2>&1; then
        echo -e "GNU grep is required. Install it with 'brew install grep'." >&2
        exit 1
    fi
fi

### ###

show_help() {
    cat <<'EOF'
USAGE:
    ipsoak [OPTIONS]  [--] [FILE]...

EXAMPLES:
    ipsoak --source data.txt
    ipsoak -s "192.168.1.1/24,10.10.10.25,2404:6800:4008:c02::8b" -m ipv6
    ipsoak --geolocation -s https://example.com/log.txt

OPTIONS:
    -s, --source                      Choose the source data to extract ips from
    -m  --mode <type>                 Choose the mode of extraction (ipv4,ipv6,both)
    -h  --help                        Print help information
        --geolocation                 Geolocate all the ip matches
EOF
}

data_source_is_empty() {
    echo -e "You need to provide a valid source of data (file, text or url). Example: ipsoak -s log.dat"
    exit 1
}

is_empty() {
    local var=$1

    [[ -z $var ]]
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

extract_json_property() {
    local json="$1"
    local property="$2"

    if command_exists "jq"; then 
        echo "$json" | jq ".$property"
    else 
        # Use grep to match the property name and extract the value
        local regex="\"${property}\":\s*([^,}]+)"
        if [[ $json =~ $regex ]]; then
            local value="${BASH_REMATCH[1]}"

            # If the value is a string with quotes, remove them
            if [[ $value =~ ^\"(.*)\"$ ]]; then
                echo "${BASH_REMATCH[1]}"
            else
                echo "$value"
            fi
        else
            # If the property is not found, return an empty string
            echo ""
        fi
    
    fi
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

###
#JSON STRUCTURE EXAMPLE
# {"status":"success","description":"Data successfully received.","data":{"geo":{"host":"74.220.199.8","ip":"74.220.199.8","rdns":"parking.hostmonster.com","asn":46606,"isp":"UNIFIEDLAYER-AS-1","country_name":"United States","country_code":"US","region_name":null,"region_code":null,"city":null,"postal_code":null,"continent_name":"North America","continent_code":"NA","latitude":37.751,"longitude":-97.822,"metro_code":null,"timezone":"America\/Chicago","datetime":"2023-03-18 04:23:49"}}}
###
geolocate_ip() { 
    local ip_address=$1
    # The user agent only needs to have this format, it does not need to be a real domain or ip
    local user_agent='keycdn-tools:http://10.10.10.25'
    local url="https://tools.keycdn.com/geo.json?host=$ip_address"

    if command_exists 'curl'; then 
        curl -s -H "User-Agent: $user_agent" "$url"

    elif command_exists 'wget'; then 
        wget -qO- --user-agent="$user_agent" "$url"
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

    is_empty "$source" && data_source_is_empty

    if [ -f "$source" ]; then
        DATA_SOURCE_TYPE='file'
    fi 
    
    if is_url "$source"; then 
        DATA_SOURCE_TYPE='url'
    fi

    DATA_SOURCE=$source
}

calculate_geolocation() {
    if ! is_empty "$IP4_MATCHES"; then
        readarray -t ip_addreses <<< "$IP4_MATCHES"

        for ip in "${ip_addreses[@]}"; do
            if [[ ! -v IP_GEOLOCATION_DICTIONARY["$ip"] ]]; then 
                IP_GEOLOCATION_DICTIONARY[$ip]=$(geolocate_ip "$ip")
            fi
        done 
    fi

    if ! is_empty "$IP6_MATCHES"; then 
        readarray -t <<< "$IP6_MATCHES"

        for ip in "${MAPFILE[@]}"; do 
            if [[ ! -v IP_GEOLOCATION_DICTIONARY["$ip"] ]]; then 
                IP_GEOLOCATION_DICTIONARY[$ip]=$(geolocate_ip "$ip")
            fi
        done 
    fi
}

remove_duplicates() {
    local text=$1
    echo "$text" | sort -u --numeric-sort
}

extract_ip_addreses_based_on_mode() {
    if is_empty "$DATA_SOURCE"; then
        data_source_is_empty
    fi

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
}

function classify_ips() {
    local ips=$1
    echo "$ips" | tr ' ' '\n' | sort | uniq -c | sort -nr | awk '{print $2"\t"$1}'
}

build_information_table() {
    table_header="IP-ADDRESS COUNT COUNTRY LATITUDE LONGITUDE\n"

    ! is_empty "$IP4_MATCHES" && { [ "$MODE" = 'ipv4' ] || [ "$MODE" = 'both' ]; } \
        && table_body+="$(classify_ips "$IP4_MATCHES")"

    ! is_empty "$IP6_MATCHES" && { [ "$MODE" = 'ipv6' ] || [ "$MODE" = 'both' ]; } \
        && table_body+="$(classify_ips "$IP6_MATCHES")"

    if [ $GEOLOCATION -eq 1 ]; then
        readarray -t table_rows <<< "$table_body"
        table_geo=''
        
        for row in "${table_rows[@]}"; do
            row=$(echo -n "$row" | sed 's/\n$//')

            ip=$(echo "$row" | awk '{print $1}')

            if ! is_empty "$ip" && [[ -v IP_GEOLOCATION_DICTIONARY["$ip"] ]]; then
                geo_data=${IP_GEOLOCATION_DICTIONARY["$ip"]}
                
                country_property="data.geo.country_name"
                latitude_property="data.geo.latitude"
                longitude_property="data.geo.longitude"

                if command_exists "jq"; then 
                    country_property=".$country_property"
                    latitude_property=".$latitude_property"
                    longitude_property=".$longitude_property"    

                    country=$(echo "$geo_data" | jq "$country_property" | sed 's/[[:space:]]\{1,\}/_/g' | sed 's/\"//g')
                    latitude=$(echo "$geo_data" | jq "$latitude_property")
                    longitude=$(echo "$geo_data" | jq "$longitude_property")           
                else 
                    country=$(extract_json_property "$geo_data" "$country_property" | sed 's/[[:space:]]\{1,\}/_/g' | sed 's/\"//g')
                    latitude=$(extract_json_property "$geo_data" "$latitude_property")
                    longitude=$(extract_json_property "$geo_data" "$longitude_property")
                fi
                
                table_geo+="$row $country $latitude $longitude\n"
            fi
        done 

        echo -e "$table_header $table_geo" | column -t
    else 
        echo -e "$table_header $table_body" | column -t
    fi
}

save_result_to_file() {
    local result=$1
    local filepath=$2

    if ! is_empty "$filepath"; then
        if echo "$result" > "$filepath"; then
            printf "Final IP report writed to %s" "$filepath"
        else
            printf "Failed to write IP report to %s" "$filepath"  >&2
            exit 1
        fi
    fi
}

## Check if no arguments are provided to the script
if [ "$#" -eq 0 ]; then
    data_source_is_empty
fi

for arg in "$@"; do
shift
    case "$arg" in
        '--output')            set -- "$@" '-o'   ;;
        '--geolocation')       set -- "$@" '-g'   ;;
        '--source')            set -- "$@" '-s'   ;;
        '--mode')              set -- "$@" '-m'   ;;
        '--help')              set -- "$@" '-h'   ;;
        *)                     set -- "$@" "$arg" ;;
    esac
done

while getopts ":s:m:o:gh:" arg; do
    case $arg in
        s) set_data_source "$OPTARG";;
        m) set_mode "$OPTARG";;
        o) OUTPUT_FILE="$OPTARG";;
        g) GEOLOCATION=1;;
        h | *)
            show_help
        ;;
    esac
done
shift $(( OPTIND - 1))

extract_ip_addreses_based_on_mode

if [ $GEOLOCATION -eq 1 ]; then
    calculate_geolocation
fi

result=$(build_information_table)

save_result_to_file "$result" "$OUTPUT_FILE"