#/bin/bash

## Load common functions
source scripts/utils.sh

coll_length=66 ## Better choose always 'even'
bullet_point_hex="\x09►"
red_mark="🔴"
gre_mark="🟢"
eql_mark="🔵"
previous_results=${PREVIOUS_RESULTS}
recent_results=${RECENT_RESULTS}
aggregate_reports=${aggregate_reports}
previous_urls=$(jq '.[].url' <<< ${previous_results})

_log "⚙︎ Comparison of results:"
_log "${bullet_point_hex} ${C_BLU}recent${C_END} version: ${recent_results}"
_log "${bullet_point_hex} ${C_BLU}previous${C_END} version: ${previous_results}"

_log ""
title="RESULT OF THE NEW CODE"
title_begin=$(((($coll_length-${#title})/2)))
title_center="$(printf ' %.0s' $(seq 2 $title_begin))${C_BLU}${title}${C_END}$(printf ' %.0s' $(seq 2 $title_begin))"
title_line=$(eval printf '═%.0s' {3..$coll_length})
title_space=$(printf ' %.0s' $(seq 3 $coll_length))
_log "╔$title_line╗"
_log "║$title_space║"
_log "║$title_center║"
_log "║$title_space║"
_log "╚$title_line╝"

## Iterate using only previous version
let idx=0
for previous_url in $previous_urls; do
    metric_unit=$(jq -r ".[$idx].numericUnit" <<< ${previous_results})
    previous_summary_keys=$(jq -r ".[] | select(.url==$previous_url) | .summary | keys[]" <<< ${previous_results})
    previous_metrics_keys=$(jq -r ".[] | select(.url==$previous_url) | .metrics | keys[]" <<< ${previous_results})

    _log "    ${C_WHT_NO_BOLD}🆄🆁🅻${C_END} $(jq -r ".[$idx].url" <<< ${recent_results})"
    _log "┌$(eval printf '─%.0s' {3..$coll_length})┐"

    ## for each summary compare to the new version
    _log "|   🅢 ${C_WHT}Summary (Difference)${C_END}\x09" $(($coll_length+4)) │
    for s_key in $previous_summary_keys; do
        recent_value=$(jq -r ".[$idx].summary.$s_key" <<< ${recent_results})
        previous_value=$(jq -r ".[] | select(.url==$previous_url) | .summary.$s_key" <<< ${previous_results})
        report_metric=$(jq -r ".[$idx].summary.$s_key" <<< $aggregate_reports)

        ## Greater is better
        res_value=$(bc <<< "${recent_value}-${previous_value}")
        bold_key="${C_WHT}${s_key}${C_END}"

        [[ $res_value -gt 0 ]] &&
            aggregate_reports=$(jq -c ".[$idx].summary.$s_key=\"$report_metric (${gre_mark}  ${res_value}%)\"" <<< $aggregate_reports) &&
            log_line="|      ${gre_mark}\x09Increase in ${bold_key} (${res_value}%)"

        [[ $res_value -lt 0 ]] &&
            aggregate_reports=$(jq -c ".[$idx].summary.$s_key=\"$report_metric (${red_mark}  ${res_value}%)\"" <<< $aggregate_reports) &&
            log_line="|      ${red_mark}\x09Decrease in ${bold_key} (${res_value}%)"

        [[ $res_value -eq 0 ]] &&
            aggregate_reports=$(jq -c ".[$idx].summary.$s_key=\"$report_metric (${eql_mark}  ${res_value}%)\"" <<< $aggregate_reports) &&
            log_line="|      ${eql_mark}\x09Same score in ${bold_key} (${res_value}%)"

        ## Adding raw value of metrics comparison
        aggregate_reports=$(jq -c ".[$idx].summary_diff.$s_key=${res_value}" <<< $aggregate_reports)

        _log "$log_line" $(($coll_length+7)) │

    done

    ## for each metrics compare to the new version
    _log "|   🅜 ${C_WHT}Metrics (Difference)${C_END}\x09" $(($coll_length+4)) │
    for m_key in $previous_metrics_keys; do
        recent_value=$(jq -r ".[$idx].metrics.$m_key" <<< ${recent_results})
        previous_value=$(jq -r ".[] | select(.url==$previous_url) | .metrics.$m_key" <<< ${previous_results})
        report_metric=$(jq -r ".[$idx].metrics.$m_key" <<< $aggregate_reports)

        ## Lower is better
        res_value=$(bc <<< "${recent_value}-${previous_value}")
        bold_key="${C_WHT}${m_key}${C_END}"

        [[ $res_value -gt 0 ]] &&
            aggregate_reports=$(jq -c ".[$idx].metrics.$m_key=\"$report_metric (+${res_value} ${metric_unit})\"" <<< $aggregate_reports) &&
            log_line="|      ${red_mark}\x09Increase time in ${bold_key} (${res_value} ${metric_unit})"

        [[ $res_value -lt 0 ]] &&
            aggregate_reports=$(jq -c ".[$idx].metrics.$m_key=\"$report_metric (${res_value} ${metric_unit})\"" <<< $aggregate_reports) &&
            log_line="|      ${gre_mark}\x09Decrease time in ${bold_key} (${res_value} ${metric_unit})"

        [[ $res_value -eq 0 ]] &&
            aggregate_reports=$(jq -c ".[$idx].metrics.$m_key=\"$report_metric (${res_value} ${metric_unit})\"" <<< $aggregate_reports) &&
            log_line="|      ${eql_mark}\x09Same time in ${bold_key} (${res_value} ${metric_unit})"

        ## Adding raw value of metrics comparison
        aggregate_reports=$(jq -c ".[$idx].metrics_diff.$m_key=${res_value}" <<< $aggregate_reports)
        
        _log "$log_line" $(($coll_length+7)) │

    done

    _log "└$(eval printf '─%.0s' {3..$coll_length})┘"
    _log ""
    let idx++
done

# Export Comparison Results to Output
echo "comparisonResults=${aggregate_reports}" >> "$GITHUB_OUTPUT"

## Update json report
echo "aggregate_reports=${aggregate_reports}" >> $GITHUB_ENV
_log "Comparation finished!"
