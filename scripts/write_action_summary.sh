## Load common functions
source scripts/utils.sh

## ENVs
SHOULD_COMPARE=${SHOULD_COMPARE:=false}

_log "Writing summary on action..."

## For compared values (Filled in when necessary)
export score_comparation_desc=$([[ "$SHOULD_COMPARE" != false ]] && echo '(Difference between previous)' || echo '')
export avg_performance_compared=${avg_performance_compared:=''}
export avg_accessibility_compared=${avg_accessibility_compared:=''}
export avg_best_practices_compared=${avg_best_practices_compared:=''}
export avg_seo_compared=${avg_seo_compared:=''}
export avg_pwa_compared=${avg_pwa_compared:=''}

TEMPLATE="templates/github_summary_template"
SUMMARY=$(cat ${TEMPLATE})
SUMMARY="${SUMMARY@Q}"
SUMMARY="${SUMMARY#\$\'}"
SUMMARY="${SUMMARY%\'}"
SUMMARY=$(envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" <<< ${SUMMARY})
echo -e ${SUMMARY} >> $GITHUB_STEP_SUMMARY