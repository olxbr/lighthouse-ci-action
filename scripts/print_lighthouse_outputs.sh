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
export avg_performance=$(_summary_color $(jq -r '.[].summary.performance'         <<< $JSON | awk "${awk_calc_avg}" || echo '-'))
#export emoji_performance=$(_summary_emoji ${avg_performance})
export avg_accessibility=$(_summary_color $(jq -r '.[].summary.accessibility'     <<< $JSON | awk "${awk_calc_avg}" || echo '-'))
#export emoji_accessibility=$(_summary_emoji ${avg_accessibility})
export avg_best_practices=$(_summary_color $(jq -r '.[].summary."best-practices"' <<< $JSON | awk "${awk_calc_avg}" || echo '-'))
#export emoji_best_practices=$(_summary_emoji ${avg_best_practices})
export avg_seo=$(_summary_color $(jq -r '.[].summary.seo'                         <<< $JSON | awk "${awk_calc_avg}" || echo '-'))
#export emoji_seo=$(_summary_emoji ${avg_seo})
export avg_pwa=$(_summary_color $(jq -r '.[].summary.pwa'                         <<< $JSON | awk "${awk_calc_avg}" || echo '-'))
#export emoji_pwa=$(_summary_emoji ${avg_pwa})

_log "🅢 Summary"
_log "   ├⎯⎯Performance: $(_summary_color ${avg_performance})"
_log "   ├⎯⎯Accessibility: $(_summary_color ${avg_accessibility})"
_log "   ├⎯⎯Best practices: $(_summary_color ${avg_best_practices})"
_log "   ├⎯⎯SEO: $(_summary_color ${avg_seo})"
_log "   └⎯⎯PWA: $(_summary_color ${avg_pwa})"

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
    
    snake_metric_name=$(_camel_to_snake_case ${metric_name})
    ## Exporting for Comment
    echo "avg_${snake_metric_name}=${avg}" >> ${GITHUB_ENV}
done


## Exporting variables
lighthouse_link=$(jq -r '.[]' <<< ${LINKS})
echo "lighthouse_link='$(_summary_color $lighthouse_link)'" >> ${GITHUB_ENV}
#echo "avg_performance='$(_summary_color $avg_performance)'" >> ${GITHUB_ENV}
#echo "avg_accessibility='$(_summary_color $avg_accessibility)'" >> ${GITHUB_ENV}
#echo "avg_best_practices='$(_summary_color $avg_best_practices)'" >> ${GITHUB_ENV}
#echo "avg_seo='$(_summary_color $avg_seo)'" >> ${GITHUB_ENV}
#echo "avg_pwa='$(_summary_color $avg_pwa)'" >> ${GITHUB_ENV}

echo "DEBUG: $(cat ${GITHUB_ENV})"

## Print summary to action

TEMPLATE="templates/github_summary_template"
echo "DEBUG2: $(cat ${GITHUB_ENV})"
echo "====="
env | tr -d '[[:cntrl:]]'

envsubst < $TEMPLATE
SUMMARY=$(envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${TEMPLATE})
SUMMARY="${SUMMARY@Q}"
SUMMARY="${SUMMARY#\$\'}"
SUMMARY="${SUMMARY%\'}"
echo -e ${SUMMARY} >> $GITHUB_STEP_SUMMARY
