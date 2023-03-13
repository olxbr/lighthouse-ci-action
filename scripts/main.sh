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

    _log "🅢 ${C_WHT}Summary (${url})"

    let idx=0
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
        _log "   ├⎯⎯$(_snake_case_to_hr ${snake_metric_name}): $(_summary_color ${avg})" ||
        _log "   └⎯⎯$(_snake_case_to_hr ${snake_metric_name}): $(_summary_color ${avg})"
    done

    ## Metrics (AVG)
    list_json_path=$(jq -r ".[] | select(.url==\"${url}\") | .jsonPath" <<< ${JSON})
    list_metrics_name=(firstContentfulPaint largestContentfulPaint interactive speedIndex totalBlockingTime totalCumulativeLayoutShift)
    aggregate_metrics='{}'
        
    _log "🅜 ${C_WHT}Metrics (${url})"

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
        _log "   ├⎯⎯${metric_name}: ${C_WHT}${avg} ${metric_unit}" ||
        _log "   └⎯⎯${metric_name}: ${C_WHT}${avg} ${metric_unit}"
        
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
aggregateResults=$(jq -c <<< ${aggregate_results})
echo "aggregateResults=${aggregateResults}" >> "$GITHUB_OUTPUT"

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
        _log "|   🅢 ${C_WHT}Summary (Difference)${C_END}\x09" $(($coll_length+3)) │
        for s_key in $previous_summary_keys; do
            recent_value=$(jq -r ".[$idx].summary.$s_key" <<< ${recent_results})
            previous_value=$(jq -r ".[] | select(.url==\"$previous_url\") | .summary.$s_key" <<< ${previous_results})

            ## Greater is better
            res_value=$(bc <<< "${recent_value}-${previous_value}")
            bold_key="${C_WHT}${s_key}${C_END}"

            [[ $res_value -gt 0 ]] && log_line="|     ${gre_mark}Increase in ${bold_key} (${res_value}%)"
            [[ $res_value -lt 0 ]] && log_line="|     ${red_mark}Decrease in ${bold_key} (${res_value}%)"
            [[ $res_value -eq 0 ]] && log_line="|     ${eql_mark}Same score in ${bold_key} (${res_value}%)"

            _log "$log_line" $(($coll_length+20)) │
    
        done

        ## for each metrics compare to the new version
        _log "|   🅜 ${C_WHT}Metrics (Difference)${C_END}\x09" $(($coll_length+3)) │
        for m_key in $previous_metrics_keys; do
            recent_value=$(jq -r ".[$idx].metrics.$m_key" <<< ${recent_results})
            previous_value=$(jq -r ".[] | select(.url==\"$previous_url\") | .metrics.$m_key" <<< ${previous_results})

            ## Lower is better
            res_value=$(bc <<< "${recent_value}-${previous_value}")
            bold_key="${C_WHT}${m_key}${C_END}"

            [[ $res_value -gt 0 ]] && log_line="|     ${red_mark}Increase time in ${bold_key} (${res_value} ${metric_unit})"
            [[ $res_value -lt 0 ]] && log_line="|     ${gre_mark}Decrease time in ${bold_key} (${res_value} ${metric_unit})"
            [[ $res_value -eq 0 ]] && log_line="|     ${eql_mark}Same time in ${bold_key} (${res_value} ${metric_unit})"

            _log "$log_line" $(($coll_length+20)) │

        done

        _log "└$(eval printf '─%.0s' {3..$coll_length})┘"
        _log ""
        let idx++
    done
    _log "Comparation finished!"
else
    _log "aggregateResults: ${aggregateResults}"
fi