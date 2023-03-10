#/bin/bash

## Load common functions
source scripts/utils.sh

## Declare env variables
JSON=${JSON}
RUNS=${RUNS}
LINKS=${LINKS}
URLS=(${URLS})
JSON_COMPARE_RESULTS=${JSON_COMPARE_RESULTS:-false}

calc_avg='{ sum+=$1; qtd+=1 } END { printf("%.${round}f", (sum/qtd)${multiplier} ) }'
awk_calc_avg_in_percentage=$(multiplier=*100 round=0 envsubst <<< $calc_avg)
urls_length=${#URLS[@]}
aggregate_results='[]'

_log "╔══════════════════════════════╗"
_log "║ Average of ${C_WHT}${RUNS}${C_END} RUNS and ${C_WHT}${urls_length}${C_END} URLs ║"
_log "╚══════════════════════════════╝"

for url in ${URLS[@]}; do 
    lighthouse_link=$(jq -r ".\"${url}\"" <<< ${LINKS})

    ## Summary (AVG)
    list_summary_name=(performance accessibility "best-practices" seo pwa)
    aggregate_summary='{}'
    re='^[0-9]+$'

    _log "${C_WHT}🅢 Summary (${url})${C_ENC}"

    for metric_name in ${list_summary_name[@]}; do
        let idx+=1

        ## Acquire metric
        avg=$(jq ".[] | select(.url==\"${url}\") | .summary.\"${metric_name}\"" <<< ${JSON} | awk "$awk_calc_avg_in_percentage" || echo '-')

        snake_metric_name=$(_camel_to_snake_case ${metric_name})
        echo "avg_${snake_metric_name}=${avg}" >> ${GITHUB_ENV}
        export "avg_${snake_metric_name}=${avg}"
        export "emoji_${snake_metric_name}=$(_summary_emoji ${avg})"

        ## Agregate metric to output
        camel_metric_name=$(_snake_to_camel_case ${metric_name})
        [[ ${avg} =~ ${re} ]] && 
        aggregate_summary=$(jq ". += { \"${camel_metric_name}\": ${avg} }" <<< "${aggregate_summary}") ||
        aggregate_summary=$(jq ". += { \"${camel_metric_name}\": \"${avg}\" }" <<< "${aggregate_summary}")

        [[ ${idx} -lt ${#list_summary_name[@]} ]] &&
        _log "   ├⎯⎯$(_snake_case_to_hr ${snake_metric_name}): $(_summary_color ${avg})" ||
        _log "   └⎯⎯$(_snake_case_to_hr ${snake_metric_name}): $(_summary_color ${avg})"
    done

    ## Metrics (AVG)
    list_json_path=$(jq -r ".[] | select(.url==\"${url}\") | .jsonPath" <<< ${JSON})
    list_metrics_name=(firstContentfulPaint largestContentfulPaint interactive speedIndex totalBlockingTime totalCumulativeLayoutShift)
    aggregate_metrics='{}'
        
    _log "${C_WHT}🅜 Metrics (${url})${C_END}"

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
        aggregate_metrics=$(jq ". += { ${metric_name}: ${avg} }" <<< "${aggregate_metrics}")

        ## Exporting to pr comment and summary
        snake_metric_name=$(_camel_to_snake_case ${metric_name})
        echo "avg_${snake_metric_name}=${avg}" >> ${GITHUB_ENV}
        export "avg_${snake_metric_name}=${avg}"
    done

    # Build aggregate results
    result='{}'
    result=$(jq ". += {\"url\": \"${url}\"}" <<< ${result})

    if [ -n "$lighthouse_link" ]; then
        result=$(jq ". += {\"link\": \"${lighthouse_link}\"}" <<< ${result})
    fi

    result=$(jq ". += {\"summary\": ${aggregate_summary}, \"metrics\": ${aggregate_metrics}}" <<< ${result})
    aggregate_results=$(jq ". += [${result}]" <<< ${aggregate_results})

    # Evaluating env vars to use in templates
    export EVALUATED_URL=$([ "$urls_length" -gt "1" ] && echo " - (${url})" || echo "")
    export EVALUATED_LIGHTHOUSE_LINK=$([ -n "$lighthouse_link" ] && echo "> _For full web report see [this page](${lighthouse_link})._")

    # Lhci Configs
    export COLLECT_PRESET=${LHCI_COLLECT__SETTINGS__PRESET:-mobile}

    # Summary
    export LIGHTHOUSE_PERFORMANCE=${avg_performance:='-'}
    export LIGHTHOUSE_ACESSIBILITY=${avg_accessibility:='-'}
    export LIGHTHOUSE_BP=${avg_best_practices:='-'}
    export LIGHTHOUSE_SEO=${avg_seo:='-'}
    export PERFORMANCE_EMOJI=$(_summary_emoji ${LIGHTHOUSE_PERFORMANCE})
    export ACESSIBILITY_EMOJI=$(_summary_emoji ${LIGHTHOUSE_ACESSIBILITY})
    export BP_EMOJI=$(_summary_emoji ${LIGHTHOUSE_BP})
    export SEO_EMOJI=$(_summary_emoji ${LIGHTHOUSE_SEO})
    export PWA_EMOJI=$(_summary_emoji ${LIGHTHOUSE_PWA})
    export PERFORMANCE_COLOR=$(_badge_color ${LIGHTHOUSE_PERFORMANCE})
    export ACESSIBILITY_COLOR=$(_badge_color ${LIGHTHOUSE_ACESSIBILITY})
    export BP_COLOR=$(_badge_color ${LIGHTHOUSE_BP})
    export SEO_COLOR=$(_badge_color ${LIGHTHOUSE_SEO})
    export PWA_COLOR=$(_badge_color ${LIGHTHOUSE_PWA})

    # Metrics
    export U_TIME=${unit_time:='-'}
    export LIGHTHOUSE_PWA=${avg_pwa:='-'}
    export LIGHTHOUSE_FCP=${avg_first_contentful_paint:='-'}
    export LIGHTHOUSE_SI=${avg_speed_index:='-'}
    export LIGHTHOUSE_LCP=${avg_largest_contentful_paint:='-'}
    export LIGHTHOUSE_TBT=${avg_total_blocking_time:='-'}
    export LIGHTHOUSE_CLS=${avg_total_cumulative_layout_shift:='-'}
    export LIGHTHOUSE_TI=${avg_interactive:='-'}

    ## Print summary to action
    TEMPLATE="templates/github_summary_template"
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

# Export Aggregate Results to Output
_log "aggregateResults: ${aggregate_results}"
echo "aggregateResults='$(jq -c <<< ${aggregate_results})'" >> "$GITHUB_OUTPUT"

# Compare results if current metrics (When necessary)
if [[ "${JSON_COMPARE_RESULTS}" != false ]]; then
    bullet_point_hex='\xe2\x80\xa2'
    _log "Comparison of results:"
    _log "  ${bullet_point_hex} ${C_GRE}New${C_END} result: ${JSON_COMPARE_RESULTS}"
    _log "  ${bullet_point_hex} ${C_GRE}Current${C_END} result: ${aggregate_results}"
fi