#/bin/bash

## Load common functions
source scripts/utils.sh

## Declare env variables
JSON=${JSON}
RUNS=${RUNS}
LINKS=${LINKS}
URLS=(${URLS})
PREVIOUS_RUN=${PREVIOUS_RUN:-false}

calc_avg='{ sum+=$1; qtd+=1 } END { printf("%.${round}f", (sum/qtd)${multiplier} ) }'
awk_calc_avg_in_percentage=$(multiplier=*100 round=0 envsubst <<< $calc_avg)
urls_length=${#URLS[@]}
aggregate_results='[]'
aggregate_reports='[]'

print_runs="${C_WHT}${RUNS}${C_END}"
print_urls_len="${C_WHT}${urls_length}${C_END}"

_log "╔══════════════════════════════╗"
_log "║ Average of ${print_runs} RUNS and ${print_urls_len} URLs ║"
_log "╚══════════════════════════════╝"

for url in ${URLS[@]}; do 
    lighthouse_link=$(jq -r ". | to_entries[] | select(.key==\"${url%/}\" or .key==\"${url%/}/\") | .value" <<< ${LINKS})

    ## Summary (AVG)
    list_summary_name=(performance accessibility "best-practices" seo pwa)
    aggregate_summary='{}'
    aggregate_summary_report='{}'

    _log "${E_SUM} ${C_WHT}Summary (${url})"

    let idx=0
    for metric_name in ${list_summary_name[@]}; do
        let idx+=1

        ## Acquire metric
        avg=$(jq ".[] | select(.url==\"${url}\") | .summary.\"${metric_name}\"" <<< ${JSON} | awk "$awk_calc_avg_in_percentage" || echo '"-"')

        ## Agregate metric to output
        camel_metric_name=$(_snake_to_camel_case ${metric_name})
        aggregate_summary=$(jq ". += { ${camel_metric_name}: ${avg} }" <<< "${aggregate_summary}")
        aggregate_summary_report=$(jq ". += { ${camel_metric_name}: \"$(_summary_color ${avg})\" }" <<< "${aggregate_summary_report}")

        [[ ${idx} -lt ${#list_summary_name[@]} ]] &&
        _log "   ├⎯⎯$(_snake_case_to_hr ${metric_name}): $(_summary_color ${avg})" ||
        _log "   └⎯⎯$(_snake_case_to_hr ${metric_name}): $(_summary_color ${avg})"
    done

    ## Metrics (AVG)
    list_json_path=$(jq -r ".[] | select(.url==\"${url}\") | .jsonPath" <<< ${JSON})
    list_metrics_name=(firstContentfulPaint largestContentfulPaint interactive speedIndex totalBlockingTime totalCumulativeLayoutShift)
    aggregate_metrics='{}'

    _log "${E_MET} ${C_WHT}Metrics (${url})"

    ## Get unit time
    unit_time="$(jq -r '.audits.metrics.numericUnit' <<< $(cat ${list_json_path}))"
    [[ "${unit_time}" =~ milli ]] && 
        export metric_unit="ms" round=0 ||
        export metric_unit="s"  round=2

    awk_calc_avg=$(multiplier=*1 round=${round} envsubst <<< $calc_avg)

    let idx=0
    for metric_name in ${list_metrics_name[@]}; do
        let idx+=1

        ## Acquire metric
        avg=$(jq -r ".audits.metrics.details.items[].${metric_name} | select (.!=null)" <<< $(cat ${list_json_path}) | awk "${awk_calc_avg}")

        ## Print output
        [[ ${idx} -lt ${#list_metrics_name[@]} ]] &&
        _log "   ├⎯⎯${metric_name}: ${C_WHT}${avg} ${metric_unit}" ||
        _log "   └⎯⎯${metric_name}: ${C_WHT}${avg} ${metric_unit}"
        
        ## Agregate metric to output
        aggregate_metrics=$(jq ". += { ${metric_name}: ${avg} }" <<< "${aggregate_metrics}")

    done

    # Build aggregate results
    result='{}'
    result=$(jq ". += {\"url\": \"${url}\"}" <<< ${result})
    result=$(jq ". += {\"numericUnit\": \"${metric_unit}\"}" <<< ${result})

    if [ -n "$lighthouse_link" ]; then
        result=$(jq ". += {\"link\": \"${lighthouse_link}\"}" <<< ${result})
    fi

    result=$(jq ". += {\"summary\": ${aggregate_summary}, \"metrics\": ${aggregate_metrics}}" <<< ${result})
    aggregate_results=$(jq -c ". += [${result}]" <<< ${aggregate_results})
    aggregate_reports=$(jq -c ". += [${result}]" <<< "$(jq -c ".summary=\"$aggregate_summary_report\"}" <<< $aggregate_results)")

done

# Export Aggregate Results to Output
echo "aggregateResults=${aggregate_results}" >> "$GITHUB_OUTPUT"
_log "aggregateResults: ${aggregate_results}"

# Export Reports for later reports (Summary and Pr comment)
echo "aggregate_reports=${aggregate_reports}" >> $GITHUB_ENV