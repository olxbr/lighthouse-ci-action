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
    
    percent=$(bc <<< $1*100)
    
    [[ $(bc <<< "$percent>=90") == 1 && $(bc <<< "$percent<=99") == 1 ]] &&
        printf "${C_GRE}%.1f%%${C_END} ${E_GRE}" $percent &&
        return
        
    [[ $(bc <<< "$percent<=89") == 1 && $(bc <<< "$percent>=50") == 1 ]] &&
        printf "${C_YEL}%.1f%%${C_END} ${E_YEL}" $percent &&
        return

    [[ $(bc <<< "$percent==100") == 1 ]] &&
        printf "${C_GRE}%.1f%%${C_END} ${E_TRO}" $percent &&
        return
        
    printf "${C_RED}%.1f%%${C_END} ${E_RED}" $percent
}

function _camel_to_snake_case () {

    echo $1 | sed 's/\([^A-Z]\)\([A-Z0-9]\)/\1_\2/g' \
        | sed 's/\([A-Z0-9]\)\([A-Z0-9]\)\([^A-Z]\)/\1_\2\3/g' \
        | tr '[:upper:]' '[:lower:]'
}
