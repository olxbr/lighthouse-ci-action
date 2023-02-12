#/bin/bash

## Colors
export ESC_SEQ='\033['
export C_END=$ESC_SEQ'0m'
export C_GRE=$ESC_SEQ'1;32m'
export C_YEL=$ESC_SEQ'1;33m'
export C_RED=$ESC_SEQ'1;31m'
export C_WHT=$ESC_SEQ'1;37m'

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

    msg=$( (($#>1)) && echo ${2} || echo ${1} )

    echo -e "$(date +"%d-%b-%Y %H:%M:%S") ${logLevel} - ${msg}"
}

function _summary_color() {
    ! [[ $1 =~ ^[0-9] ]] && printf "${C_RED}${1}${C_END}" && return ## not a number

    [[ $(bc <<< "$1>=90") == 1 && $(bc <<< "$1<=99") == 1 ]] &&
        printf "${E_GRE} ${C_GRE}%.1f%%${C_END}" $1 &&
        return

    [[ $(bc <<< "$1<=89") == 1 && $(bc <<< "$1>=50") == 1 ]] &&
        printf "${E_YEL} ${C_YEL}%.1f%%${C_END}" $1 &&
        return

    [[ $(bc <<< "$1==100") == 1 ]] &&
        printf "${E_TRO} ${C_GRE}%.1f%%${C_END}" $1 &&
        return

    printf "${E_RED} ${C_RED}%.1f%%${C_END}" $1
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
    echo $1 | sed -E 's,([A-Z]),_\1,g' | tr '[:upper:]' '[:lower:]'
}
