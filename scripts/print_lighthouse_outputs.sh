#/bin/bash

## Load common functions
source scripts/utils.sh

## Declare env variables
JSON=${JSON}
RUNS=${RUNS}

awk_calc_avg='{ sum+=$1; qtd+=1 } END {print (sum/qtd)}'

_log "#########################"
_log "### Average of ${C_WHT}${RUNS}${C_END} runs ###"
_log "#########################"

## Summary (AVG)
avg_performance=$(jq -r '.[].summary.performance'         <<< $JSON | awk "${awk_calc_avg}" || echo '-')
avg_accessibility=$(jq -r '.[].summary.accessibility'     <<< $JSON | awk "${awk_calc_avg}" || echo '-')
avg_best_practices=$(jq -r '.[].summary."best-practices"' <<< $JSON | awk "${awk_calc_avg}" || echo '-')
avg_seo=$(jq -r '.[].summary.seo'                         <<< $JSON | awk "${awk_calc_avg}" || echo '-')
avg_pwa=$(jq -r '.[].summary.pwa'                         <<< $JSON | awk "${awk_calc_avg}" || echo '-')

_log "🅢 Summary"
_log "   ├⎯⎯Performance: $(_summaryColor ${avg_performance})"
_log "   ├⎯⎯Accessibility: $(_summaryColor ${avg_accessibility})"
_log "   ├⎯⎯Best practices: $(_summaryColor ${avg_best_practices})"
_log "   ├⎯⎯SEO: $(_summaryColor ${avg_seo})"
_log "   └⎯⎯PWA: $(_summaryColor ${avg_pwa})"

## Metrics (AVG)
list_json_path=$(jq -r '.[].jsonPath' <<< ${JSON})
list_metrics_name=(firstContentfulPaint largestContentfulPaint interactive speedIndex totalBlockingTime totalCumulativeLayoutShift)
    
_log "🅜 Metrics"

## Get unit time
unit_time="$(jq -r '.audits.metrics.numericUnit' <<< $(cat ${list_json_path}))"
[[ "${unit_time}" =~ milli ]] && 
    metric_unit="ms" ||
    metric_unit="s"

for metric_name in ${list_metrics_name[@]}; do
    let idx+=1
    avg=$(jq -r ".audits.metrics.details.items[].${metric_name} | select (.!=null)" <<< $(cat ${list_json_path}) | awk "${awk_calc_avg}")

    [[ ${idx} -lt ${#list_metrics_name[@]} ]] &&
    _log "   ├⎯⎯${metric_name}: ${C_WHT}${avg} ${metric_unit}${C_END}" ||
    _log "   └⎯⎯${metric_name}: ${C_WHT}${avg} ${metric_unit}${C_END}"
    
    ## Exporting for Comment
    echo "avg_${metric_name}=${metric_name}" >> ${GITHUB_ENV}
done


## Exporting variables
lighthouse_link=$(jq -r '.[]' <<< ${LINKS})
echo "lighthouse_link=${lighthouse_link}" >> ${GITHUB_ENV}
echo "avg_performance=${avg_performance}" >> ${GITHUB_ENV}
echo "avg_accessibility=${avg_accessibility}" >> ${GITHUB_ENV}
echo "avg_best_practices=${avg_best_practices}" >> ${GITHUB_ENV}
echo "avg_seo=${avg_seo}" >> ${GITHUB_ENV}
echo "avg_pwa=${avg_pwa}" >> ${GITHUB_ENV}

## Print summary to action

TEMPLATE="templates/github_summary_template"
SUMMARY=$(envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${TEMPLATE})
echo ${SUMMARY} >> $GITHUB_STEP_SUMMARY
