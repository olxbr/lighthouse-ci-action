#/bin/bash

## Load common functions
source scripts/utils.sh

# Lhci Configs
export COLLECT_PRESET=${LHCI_COLLECT__SETTINGS__PRESET:-mobile}

## Declare env variables
JSON=${JSON}
RUNS=${RUNS}

calc_avg='{ sum+=$1; qtd+=1 } END { printf("%.${round}f", (sum/qtd)${multiplier} ) }'
awk_calc_avg_in_percentage=$(multiplier=*100 round=0 envsubst <<< $calc_avg)

_log "#########################"
_log "### Average of ${C_WHT}${RUNS}${C_END} runs ###"
_log "#########################"

## Summary (AVG)
list_summary_name=(performance accessibility "best-practices" seo pwa)
aggregatedSumary=$(echo "{}")
re='^[0-9]+$'

_log "🅢 Summary"

for metric_name in ${list_summary_name[@]}; do
    let idx+=1

    ## Acquire metric
    avg=$(jq -r ".[].summary.\"${metric_name}\"" <<< $JSON | awk "$awk_calc_avg_in_percentage" || echo '-')

    snake_metric_name=$(_camel_to_snake_case ${metric_name})
    echo "avg_${snake_metric_name}=${avg}" >> ${GITHUB_ENV}
    export "avg_${snake_metric_name}=${avg}"
    export "emoji_${snake_metric_name}=$(_summary_emoji ${avg})"

    ## Agregate metric to output
    [[ ${avg} =~ ${re} ]] && 
    aggregatedSumary=$(jq ". += { \"${metric_name}\": ${avg} }" <<< "${aggregatedSumary}") ||
    aggregatedSumary=$(jq ". += { \"${metric_name}\": \"${avg}\" }" <<< "${aggregatedSumary}")

    [[ ${idx} -lt ${#list_summary_name[@]} ]] &&
    _log "   ├⎯⎯$(_snake_case_to_hr ${snake_metric_name}): $(_summary_color ${avg})" ||
    _log "   └⎯⎯$(_snake_case_to_hr ${snake_metric_name}): $(_summary_color ${avg})"
done

## Metrics (AVG)
list_json_path=$(jq -r '.[].jsonPath' <<< ${JSON})
list_metrics_name=(firstContentfulPaint largestContentfulPaint interactive speedIndex totalBlockingTime totalCumulativeLayoutShift)
aggregatedMetrics=$(echo "{}")
    
_log "🅜 Metrics"

## Get unit time
unit_time="$(jq -r '.audits.metrics.numericUnit' <<< $(cat ${list_json_path}))"
[[ "${unit_time}" =~ milli ]] && 
    export metric_unit="ms" round=0 ||
    export metric_unit="s"  round=2

echo "unit_time=${metric_unit}" >> ${GITHUB_ENV}

awk_calc_avg=$(multiplier=*1 round=${round} envsubst <<< $calc_avg)

let idx=0
for metric_name in ${list_metrics_name[@]}; do
    let idx+=1

    ## Acquire metric
    avg=$(jq -r ".audits.metrics.details.items[].${metric_name} | select (.!=null)" <<< $(cat ${list_json_path}) | awk "${awk_calc_avg}")

    ## Print output
    [[ ${idx} -lt ${#list_metrics_name[@]} ]] &&
    _log "   ├⎯⎯${metric_name}: ${C_WHT}${avg} ${metric_unit}${C_END}" ||
    _log "   └⎯⎯${metric_name}: ${C_WHT}${avg} ${metric_unit}${C_END}"
    
    ## Agregate metric to output
    aggregatedMetrics=$(jq ". += { ${metric_name}: ${avg} }" <<< "${aggregatedMetrics}")

    ## Exporting to pr comment and summary
    snake_metric_name=$(_camel_to_snake_case ${metric_name})
    echo "avg_${snake_metric_name}=${avg}" >> ${GITHUB_ENV}
done


## Exporting variables
lighthouse_link=$(jq -r 'to_entries | .[0].value' <<< ${LINKS})
echo "lighthouse_link=$lighthouse_link" >> ${GITHUB_ENV}
echo "avg_performance=$avg_performance" >> ${GITHUB_ENV}
echo "avg_accessibility=$avg_accessibility" >> ${GITHUB_ENV}
echo "avg_best_practices=$avg_best_practices" >> ${GITHUB_ENV}
echo "avg_seo=$avg_seo" >> ${GITHUB_ENV}
echo "avg_pwa=$avg_pwa" >> ${GITHUB_ENV}


## Export json output
_log info "Generating output of this action"
_log info "aggregatedSumary='${aggregatedSumary}'"
_log info "aggregatedMetrics='${aggregatedMetrics}'"
echo "aggregatedSumary='$(jq -c <<< ${aggregatedSumary})'" >> "$GITHUB_OUTPUT"
echo "aggregatedMetrics='$(jq -c <<< ${aggregatedMetrics})'" >> "$GITHUB_OUTPUT"


## Print summary to action
TEMPLATE="templates/github_summary_template"
SUMMARY=$(envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${TEMPLATE})
SUMMARY="${SUMMARY@Q}"
SUMMARY="${SUMMARY#\$\'}"
SUMMARY="${SUMMARY%\'}"
echo -e ${SUMMARY} >> $GITHUB_STEP_SUMMARY
