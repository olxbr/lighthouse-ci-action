#/bin/bash

## Load common functions
source scripts/utils.sh

## Declare env variables
branch_to_compare=${BRANCH_TO_COMPARE}

# Compare results recent code with previous (When necessary)
if [[ "${JSON_COMPARE_RESULTS}" != false ]]; then

coll_length=66 ## Better choose always 'even'
bullet_point_hex="\x09►"
red_mark="${C_RED}🔴\x09${C_END}"
gre_mark="${C_GRE}🟢\x09${C_END}"
eql_mark="${C_BLU}🔵\x09${C_END}"
previous_results=${aggregateResults}
recent_results=${JSON_COMPARE_RESULTS}
previous_urls=$(jq -r '.[].url' <<< ${previous_results})

_log ""
_log "⚙︎ Comparison of results:"
_log "${bullet_point_hex} ${C_BLU}recent${C_END} version: ${recent_results}"
_log "${bullet_point_hex} ${C_BLU}previous${C_END} version: ${previous_results}"

_log ""
_log ""
title="RESULT OF THE NEW CODE"
title_begin=$(((($coll_length-${#title})/2)))
title_center="$(printf '\\x20%.0s' $(seq 2 $title_begin))${C_BLU}${title}${C_END}$(printf '\\x20%.0s' $(seq 2 $title_begin))"
title_line=$(eval printf '═%.0s' {3..$coll_length})
title_space=$(printf '\\x20%.0s' $(seq 3 $coll_length))
_log "╔$title_line╗"
_log "║$title_space║"
_log "║$title_center║"
_log "║$title_space║"
_log "╚$title_line╝"

## Iterate using only previous version
let idx=0
for previous_url in $previous_urls; do
    previous_summary_keys=$(jq -r ".[] | select(.url==\"$previous_url\") | .summary | keys[]" <<< ${previous_results})
    previous_metrics_keys=$(jq -r ".[] | select(.url==\"$previous_url\") | .metrics | keys[]" <<< ${previous_results})

    _log "    ${C_WHT_NO_BOLD}🆄🆁🅻${C_END} $(jq -r ".[$idx].url" <<< ${recent_results})"
    _log "┌$(eval printf '─%.0s' {3..$coll_length})┐"

    ## for each summary compare to the new version
    _log "|   🅢 ${C_WHT}Summary (Difference)${C_END}\x09" $(($coll_length+1)) │
    for s_key in $previous_summary_keys; do
        recent_value=$(jq -r ".[$idx].summary.$s_key" <<< ${recent_results})
        previous_value=$(jq -r ".[] | select(.url==\"$previous_url\") | .summary.$s_key" <<< ${previous_results})

        ## Greater is better
        res_value=$(bc <<< "${recent_value}-${previous_value}")
        bold_key="${C_WHT}${s_key}${C_END}"

        [[ $res_value -gt 0 ]] && log_line="|      ${gre_mark}Increase in ${bold_key} (${res_value}%)"
        [[ $res_value -lt 0 ]] && log_line="|      ${red_mark}Decrease in ${bold_key} (${res_value}%)"
        [[ $res_value -eq 0 ]] && log_line="|      ${eql_mark}Same score in ${bold_key} (${res_value}%)"

        _log "$log_line" $(($coll_length+15)) │

    done

    ## for each metrics compare to the new version
    _log "|   🅜 ${C_WHT}Metrics (Difference)${C_END}\x09" $(($coll_length+1)) │
    for m_key in $previous_metrics_keys; do
        recent_value=$(jq -r ".[$idx].metrics.$m_key" <<< ${recent_results})
        previous_value=$(jq -r ".[] | select(.url==\"$previous_url\") | .metrics.$m_key" <<< ${previous_results})

        ## Lower is better
        res_value=$(bc <<< "${recent_value}-${previous_value}")
        bold_key="${C_WHT}${m_key}${C_END}"

        [[ $res_value -gt 0 ]] && log_line="|      ${red_mark}Increase time in ${bold_key} (${res_value} ${metric_unit})"
        [[ $res_value -lt 0 ]] && log_line="|      ${gre_mark}Decrease time in ${bold_key} (${res_value} ${metric_unit})"
        [[ $res_value -eq 0 ]] && log_line="|      ${eql_mark}Same time in ${bold_key} (${res_value} ${metric_unit})"

        _log "$log_line" $(($coll_length+15)) │

    done

    _log "└$(eval printf '─%.0s' {3..$coll_length})┘"
    _log ""
    let idx++
done
_log "Comparation finished!"