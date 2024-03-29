#/bin/bash

## Colors
export ESC_SEQ='\033['
export C_END=$ESC_SEQ'0m'
export C_GRE=$ESC_SEQ'1;32m'
export C_YEL=$ESC_SEQ'1;33m'
export C_BLU=$ESC_SEQ'1;34m'
export C_RED=$ESC_SEQ'1;31m'
export C_WHT=$ESC_SEQ'1;37m'
export C_WHT_NO_BOLD=$ESC_SEQ'0;37m'

export E_GRE='\xE2\x9C\x85'
export E_YEL='\xE2\x9A\xA0'
export E_RED='\xE2\x9D\x97'
export E_TRO='\xF0\x9F\x8F\x86'
export E_SUM='\xF0\x9F\x85\xA2'
export E_MET='\xF0\x9F\x85\x9C'

function _log() {
    case $1 in
        erro) logLevel="${C_RED}[ERRO]${C_END}";;
        warn) logLevel="${C_YEL}[WARN]${C_END}";;
        debug) [[ $ACTIONS_RUNNER_DEBUG == true ]] && logLevel="${C_YEL}[DEBUG]${C_END}" || return;;
        *)    logLevel="${C_WHT}[INFO]${C_END}";;
    esac

    msg=$( (($#==2)) && echo "${2}" || echo "${1}" )
    if (($#>2)); then
        msg_evaluated=$(echo -e $msg) ## Transform hex to char
        msg_length=$(echo ${#msg_evaluated})
        msg_total_coll=$2
        msg_last_char=$3
        msg_more=$(($msg_total_coll-$msg_length))
        msg_space_end=$(printf '\\x20%.0s' $(seq 1 $(($msg_total_coll-$msg_length))))
        msg="${msg}${msg_space_end}${msg_last_char}"
    fi

    echo -e "$(date +"%d-%b-%Y %H:%M:%S") ${logLevel} - ${msg}${C_END}"
}

function _summary_color() {
    ! [[ $1 =~ ^[0-9] ]] && printf "${C_RED}${1}${C_END}" && return ## not a number

    ## Print for json
    [[ "$2" == "clean" ]] && print_clean=true || print_clean=false

    [[ $1 -ge 90 && $1 -le 99 ]] &&
        ([[ $print_clean == true ]] &&
            printf "${E_GRE} $1%%" ||
            printf "${E_GRE} ${C_GRE}$1%%${C_END}") &&
        return

    [[ $1 -le 89 && $1 -ge 50 ]] &&
        ([[ $print_clean == true ]] &&
            printf "${E_YEL} $1%%" ||
            printf "${E_YEL} ${C_YEL}$1%%${C_END}") &&
        return

    [[ $1 -eq 100 ]] &&
        ([[ $print_clean == true ]] &&
            printf "${E_TRO} $1%%" ||
            printf "${E_TRO} ${C_GRE}$1%%${C_END}") &&
        return

    [[ $print_clean == true ]] &&
        printf "${E_RED} $1%%" ||
        printf "${E_RED} ${C_RED}$1%%${C_END}"
}

function _badge_color() {
    ## Get only number from string
    only_num=${1//%*/}
    only_num=${only_num//[!0-9]/}

    ! [[ $only_num =~ ^[0-9] ]] && printf "red" && return ## not a number

    [[ $only_num -ge 90 ]] &&
        printf "brightgreen" &&
        return

    [[ $only_num -le 89 && $only_num -ge 50 ]] &&
        printf "yellow" &&
        return

    printf "red"
}

function _summary_emoji() {
    ! [[ $1 =~ ^[0-9] ]] && printf "" && return ## not a number

    [[ $(bc <<< "$1>=90") == 1 && $(bc <<< "$1<=99") == 1 ]] &&
        printf "${E_GRE}" $1 &&
        return

    [[ $(bc <<< "$1<=89") == 1 && $(bc <<< "$1>=50") == 1 ]] &&
        printf "${E_YEL}" $1 &&
        return

    [[ $(bc <<< "$1==100") == 1 ]] &&
        printf "${E_TRO}" $1 &&
        return

    printf "${E_RED}" $1
}

function _snake_to_camel_case () {
    echo $1 | sed -E 's/[_-]([a-z])/\U\1/g'
}

function _snake_case_to_hr () {
    size=$(expr "$1" : '.*')
    [[ $size -le 3 ]] && tr '[:lower:]' '[:upper:]' <<< "$1" && return
    echo $1 | sed -E 's,(\_), ,g' | awk '{for(i=1;i<=NF;i++){ $i=toupper(substr($i,1,1)) substr($i,2) }}1'
}

function _set_up_lhci_env_vars() {
    _log "Setting environment variables:"
    while [ $# -gt 0 ]; do
        case "$1" in
            --collectPreset=*)
                collectPreset="${1#*=}"
                if [ -n "$collectPreset" ]; then
                    _log "LHCI_COLLECT__SETTINGS__PRESET=\"$collectPreset\""
                    echo "LHCI_COLLECT__SETTINGS__PRESET=$collectPreset" >> ${GITHUB_ENV}
                fi
                shift
                ;;
            --chromeFlags=*)
                chrome_flags="${1#*=}"
                if [ -n "$chrome_flags" ]; then
                    _log "LHCI_COLLECT__SETTINGS__CHROME_FLAGS=\"$chrome_flags\""
                    echo "LHCI_COLLECT__SETTINGS__CHROME_FLAGS=$chrome_flags" >> ${GITHUB_ENV}
                fi
                shift
                ;;
            *)
                echo "Unknown option: $1"
                shift
                ;;
        esac
    done
}

function _check_url_availability() {
    local urls=($@)
    local timeout=5
    local retries=5
    local sleep=1

    local count=0
    local available=false

    if [[ -z "${urls[@]}" ]]; then 
        _log warn "No urls to check availability"
        return
    fi

    _log "Checking availability of ${#urls[@]} urls with timeout: ${timeout}s - retries: ${retries} - sleep: ${sleep}s"

    for url in ${urls[@]}; do
        while [[ $count -lt $retries ]]; do
            curl_response=$(curl --write-out '%{http_code}' --output /dev/null --silent --head --fail --max-time $timeout "${url}" || true)
            if [[ "${curl_response}" =~ ^[23].. ]]; then
                available=true
                break
            else
                _log warn "URL ${url} is not available. Retrying in ${sleep}s..."
                count=$((count+1))
                sleep $sleep
                _log "Retrying... ${count}/${retries}"
            fi
        done
        if [[ $available == false ]]; then
            _log erro "URL ${url} is not available. Please check the url [${url}] or if the status code is different from 2xx [${curl_response}] and try again."
            exit 1
        fi
        _log "URL ${url} is available with status code [${curl_response}]. Proceeding..."
    done
}
