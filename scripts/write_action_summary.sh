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

## For compared values
export score_comparation_desc=$([[ "$SHOULD_COMPARE" != false ]] && echo '(Comparison with previous url)' || echo '')
export avg_performance_compared=${avg_performance_compared:=''}
export avg_accessibility_compared=${avg_accessibility_compared:=''}
export avg_best_practices_compared=${avg_best_practices_compared:=''}
export avg_seo_compared=${avg_seo_compared:=''}
export avg_pwa_compared=${avg_pwa_compared:=''}

TEMPLATE="templates/github_summary_template"
SUMMARY=$(envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${TEMPLATE})
SUMMARY="${SUMMARY@Q}"
SUMMARY="${SUMMARY#\$\'}"
SUMMARY="${SUMMARY%\'}"
echo -e ${SUMMARY} >> $GITHUB_STEP_SUMMARY