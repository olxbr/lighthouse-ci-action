## Load common functions
source scripts/utils.sh

_log "Writing summary on action..."

urls=($(jq '.[].url' <<< $aggregate_reports))

for url in $urls; do

    ## Export all summary values to ENV
    $(jq -r ".[] | select(.url==$url) | .summary | keys[] as \$k | \"export \(\$k)=\(.[\$k])\"" <<< $aggregate_reports)

    # Link do Json 
    lighthouse_link=$(jq -r ".[] | select(.url==$url) | .link" <<< $aggregate_reports)

    # Lhci Configs
    export COLLECT_PRESET=${LHCI_COLLECT__SETTINGS__PRESET:-mobile}

    # Evaluating env vars to use in templates
    export EVALUATED_URL=" - (${url//\"/})"
    export EVALUATED_LIGHTHOUSE_LINK=$([ -n "$lighthouse_link" ] && echo "> _For full web report see [this page](${lighthouse_link})._")

    ## For compared values (Filled in when necessary)
    export score_comparation_desc=$([[ "$COMPARATION_WAS_EXECUTED" == true ]] && echo '(Difference between previous)' || echo '')

    TEMPLATE="templates/github_summary_template"
    SUMMARY=$(cat ${TEMPLATE})
    SUMMARY="${SUMMARY@Q}"
    SUMMARY="${SUMMARY#\$\'}"
    SUMMARY="${SUMMARY%\'}"
    SUMMARY=$(envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" <<< ${SUMMARY})
    echo -e ${SUMMARY} >> $GITHUB_STEP_SUMMARY
done

_log "Finished summary action!"