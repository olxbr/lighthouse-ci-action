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

function _log() {
    case $1 in
        erro) logLevel="${C_RED}[ERRO]${C_END}";;
        warn) logLevel="${C_YEL}[WARN]${C_END}";;
        *)    logLevel="${C_WHT}[INFO]${C_END}";;
    esac

    msg=$( (($#==2)) && echo ${2} || echo ${1} )
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

    [[ $1 -ge 90 && $1 -le 99 ]] &&
        printf "${E_GRE} ${C_GRE}$1%%${C_END}" &&
        return

    [[ $1 -le 89 && $1 -ge 50 ]] &&
        printf "${E_YEL} ${C_YEL}$1%%${C_END}" &&
        return

    [[ $1 -eq 100 ]] &&
        printf "${E_TRO} ${C_GRE}$1%%${C_END}" &&
        return

    printf "${E_RED} ${C_RED}$1%%${C_END}"
}

function _badge_color() {
    ! [[ $1 =~ ^[0-9] ]] && printf "red" && return ## not a number

    [[ $1 -ge 90 && $1 -le 99 ]] &&
        printf "green" &&
        return

    [[ $1 -le 89 && $1 -ge 50 ]] &&
        printf "yellow" &&
        return

    [[ $1 -eq 100 ]] &&
        printf "green" &&
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

function _camel_to_snake_case () {
    echo $1 | sed -E 's,([A-Z]),_\1,g' | sed -E 's,(\-),_,g' | tr '[:upper:]' '[:lower:]'
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
    ## input.collect_preset
    if [ -n "${1}" ]; then
        echo "LHCI_COLLECT__SETTINGS__PRESET=${1}" >> ${GITHUB_ENV}
    fi
}
