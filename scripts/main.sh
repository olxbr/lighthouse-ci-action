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
json_length=$(jq -r '. | length' <<< ${JSON})

_log "####################################"
_log "### Average of ${C_WHT}${RUNS}${C_END} RUNS and ${C_WHT}${json_length}${C_END} URLs ###"
_log "####################################"

## Summary (AVG)
list_summary_name=(performance accessibility "best-practices" seo pwa)
aggregatedSumary=$(echo "{}")
re='^[0-9]+$'

#Convert lenght to index to count from 0 in for
max_idx=$((${json_length}-1))

for i in $(seq 0 $max_idx); do 
    url=$(jq -r ".[${i}].url" <<< $JSON)

    _log "🅢 Summary - ${url}"

    for metric_name in ${list_summary_name[@]}; do
        let idx+=1

        ## Acquire metric
        avg=$(jq -r ".[${i}].summary.\"${metric_name}\"" <<< $JSON | awk "$awk_calc_avg_in_percentage" || echo '-')

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
    list_json_path=$(jq -r ".[${i}].jsonPath" <<< ${JSON})
    list_metrics_name=(firstContentfulPaint largestContentfulPaint interactive speedIndex totalBlockingTime totalCumulativeLayoutShift)
    aggregatedMetrics=$(echo "{}")
        
    _log "🅜 Metrics - ${url}"

    ## Get unit time
    unit_time="$(jq -r '.audits.metrics.numericUnit' <<< $(cat ${list_json_path}))"
    [[ "${unit_time}" =~ milli ]] && 
        export metric_unit="ms" round=0 ||
        export metric_unit="s"  round=2

    export unit_time=${metric_unit}

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
        export "avg_${snake_metric_name}=${avg}"
    done


    ## Exporting variables
    export lighthouse_link=$(jq -r "to_entries | .[${i}].value" <<< ${LINKS})
    export URL=${url:="https://github.com/olxbr/lighthouse-ci-action"}
    export TEMPLATE="templates/metrics_result_template"

    # Summary
    export LIGHTHOUSE_URL_REPORT=${lighthouse_link:='https://github.com/olxbr/lighthouse-ci-action'}
    export LIGHTHOUSE_PERFORMANCE=${avg_performance:='-'}
    export LIGHTHOUSE_ACESSIBILITY=${avg_accessibility:='-'}
    export LIGHTHOUSE_BP=${avg_best_practices:='-'}
    export LIGHTHOUSE_SEO=${avg_seo:='-'}
    export PERFORMANCE_EMOJI=$(_summary_emoji ${LIGHTHOUSE_PERFORMANCE})
    export ACESSIBILITY_EMOJI=$(_summary_emoji ${LIGHTHOUSE_ACESSIBILITY})
    export BP_EMOJI=$(_summary_emoji ${LIGHTHOUSE_BP})
    export SEO_EMOJI=$(_summary_emoji ${LIGHTHOUSE_SEO})
    export PWA_EMOJI=$(_summary_emoji ${LIGHTHOUSE_PWA})

    # Metrics
    export U_TIME=${unit_time:='-'}
    export LIGHTHOUSE_PWA=${avg_pwa:='-'}
    export LIGHTHOUSE_FCP=${avg_first_contentful_paint:='-'}
    export LIGHTHOUSE_SI=${avg_speed_index:='-'}
    export LIGHTHOUSE_LCP=${avg_largest_contentful_paint:='-'}
    export LIGHTHOUSE_TBT=${avg_total_blocking_time:='-'}
    export LIGHTHOUSE_CLS=${avg_total_cumulative_layout_shift:='-'}
    export LIGHTHOUSE_TI=${avg_interactive:='-'}

      ## Export json output
    _log info "Generating output of this action"
    _log info "aggregatedSumary='${aggregatedSumary}'"
    _log info "aggregatedMetrics='${aggregatedMetrics}'"
    echo "aggregatedSumary='$(jq -c <<< ${aggregatedSumary})'" >> "$GITHUB_OUTPUT"
    echo "aggregatedMetrics='$(jq -c <<< ${aggregatedMetrics})'" >> "$GITHUB_OUTPUT"


    ## Print summary to action
    SUMMARY=$(envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${TEMPLATE})
    SUMMARY="${SUMMARY@Q}"
    SUMMARY="${SUMMARY#\$\'}"
    SUMMARY="${SUMMARY%\'}"
    echo -e ${SUMMARY} >> $GITHUB_STEP_SUMMARY

    # Run Post PR Comment for each URL
    if ${COMMENT_ON_PR}; then
        bash scripts/post_pr_comment.sh
    fi
done
