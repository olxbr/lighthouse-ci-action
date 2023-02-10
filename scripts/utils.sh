#/bin/bash

## Colors
export ESC_SEQ='\033['
export C_END=$ESC_SEQ'0m'
export C_GRE=$ESC_SEQ'1;32m'
export C_YEL=$ESC_SEQ'1;33m'
export C_RED=$ESC_SEQ'1;31m'
export C_WHT=$ESC_SEQ'1;37m'

function _log() {
    case $1 in
        erro) logLevel="${C_RED}[ERRO]${C_END}";;
        warn) logLevel="${C_YEL}[WARN]${C_END}";;
        *)    logLevel="${C_WHT}[INFO]${C_END}";;
    esac

    msg=$( (($#>1)) && echo ${2} || echo ${1} )

    echo -e "$(date +"%d-%b-%Y %H:%M:%S") ${logLevel} - ${msg}"
}

function _summaryColor() {
    ! [[ $1 =~ ^[0-9] ]] && printf "${C_RED}${1}${C_END}" && return ## not a number
    
    percent=$(bc <<< $1*100)
    [[ $percent -ge 90 ]]                    && printf "${C_GRE}${percent}%%${C_END}" && return
    [[ $percent -le 89 && $percent -ge 50 ]] && printf "${C_YEL}${percent}%%${C_END}" && return
    printf "${C_RED}${percent}%%${C_END}"
}
