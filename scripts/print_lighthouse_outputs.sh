#/bin/bash

## Load common functions
source scripts/utils.sh

## Declare env variables
JSON=${JSON}
RUNS=${RUNS}

calc_avg='{ sum+=$1; qtd+=1 } END { print (sum/qtd)$multiplier }'
awk_calc_avg=$(multiplier=*1 envsubst <<< $calc_avg)
awk_calc_avg_in_percentage=$(multiplier=*100 envsubst <<< $calc_avg)

_log "#########################"
_log "### Average of ${C_WHT}${RUNS}${C_END} runs ###"
_log "#########################"

## Summary (AVG)
list_summary_name=(performance accessibility "best-practices" seo pwa)
agregatedSumary=$(echo "{}")
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
    agregatedSumary=$(jq ". += { \"${metric_name}\": ${avg} }" <<< "${agregatedSumary}") ||
    agregatedSumary=$(jq ". += { \"${metric_name}\": \"${avg}\" }" <<< "${agregatedSumary}")

    [[ ${idx} -lt ${#list_summary_name[@]} ]] &&
    _log "   ├⎯⎯$(_snake_case_to_hr ${snake_metric_name}): $(_summary_color ${avg})" ||
    _log "   └⎯⎯$(_snake_case_to_hr ${snake_metric_name}): $(_summary_color ${avg})"
done

## Metrics (AVG)
list_json_path=$(jq -r '.[].jsonPath' <<< ${JSON})
list_metrics_name=(firstContentfulPaint largestContentfulPaint interactive speedIndex totalBlockingTime totalCumulativeLayoutShift)
agregatedMetrics=$(echo "{}")
    
_log "🅜 Metrics"

## Get unit time
unit_time="$(jq -r '.audits.metrics.numericUnit' <<< $(cat ${list_json_path}))"
[[ "${unit_time}" =~ milli ]] && 
    metric_unit="ms" ||
    metric_unit="s"
echo "unit_time=${metric_unit}" >> ${GITHUB_ENV}


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
    agregatedMetrics=$(jq ". += { ${metric_name}: ${avg} }" <<< "${agregatedMetrics}")

    ## Exporting to pr comment and summary
    snake_metric_name=$(_camel_to_snake_case ${metric_name})
    echo "avg_${snake_metric_name}=${avg}" >> ${GITHUB_ENV}
done


## Exporting variables
lighthouse_link=$(jq -r '.[]' <<< ${LINKS})
echo "lighthouse_link=$lighthouse_link" >> ${GITHUB_ENV}
echo "avg_performance=$avg_performance" >> ${GITHUB_ENV}
echo "avg_accessibility=$avg_accessibility" >> ${GITHUB_ENV}
echo "avg_best_practices=$avg_best_practices" >> ${GITHUB_ENV}
echo "avg_seo=$avg_seo" >> ${GITHUB_ENV}
echo "avg_pwa=$avg_pwa" >> ${GITHUB_ENV}


## Export json output
_log info "Generating output of this action"
_log info "agregatedSumary='${agregatedSumary}'"
_log info "agregatedMetrics='${agregatedMetrics}'"
echo "agregatedSumary='$(jq -c <<< ${agregatedSumary})'" >> "$GITHUB_OUTPUT"
echo "agregatedMetrics='$(jq -c <<< ${agregatedMetrics})'" >> "$GITHUB_OUTPUT"


## Print summary to action
TEMPLATE="templates/github_summary_template"
SUMMARY=$(envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${TEMPLATE})
SUMMARY="${SUMMARY@Q}"
SUMMARY="${SUMMARY#\$\'}"
SUMMARY="${SUMMARY%\'}"
echo -e ${SUMMARY} >> $GITHUB_STEP_SUMMARY
