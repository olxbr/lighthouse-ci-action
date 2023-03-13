## Load common functions
source scripts/utils.sh

## ENVs
SHOULD_COMPARE=${SHOULD_COMPARE:=false}

_log "Writing summary on action..."

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

echo $SHOULD_COMPARE
export score_comparation_desc=$([[ "$SHOULD_COMPARE" != false ]] && echo '(Comparison with previous url)' || echo '')

TEMPLATE="templates/github_summary_template"
SUMMARY=$(envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${TEMPLATE})
SUMMARY="${SUMMARY@Q}"
SUMMARY="${SUMMARY#\$\'}"
SUMMARY="${SUMMARY%\'}"
echo -e ${SUMMARY} >> $GITHUB_STEP_SUMMARY