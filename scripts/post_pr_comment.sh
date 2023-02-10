#/bin/bash

source scripts/utils.sh

export LIGHTHOUSE_URL_REPORT=${lighthouse_link:='https://github.com/olxbr/lighthouse-ci-action'}
export LIGHTHOUSE_PERFORMANCE=${avg_performance:='-'}
export LIGHTHOUSE_ACESSIBILITY=${avg_accessibility:='-'}
export LIGHTHOUSE_BP=${avg_best_practices:='-'}
export LIGHTHOUSE_SEO=${avg_seo:='-'}
export LIGHTHOUSE_PWA=${avg_pwa:='-'}
export LIGHTHOUSE_FCP=${avg_fcp:='-'}
export LIGHTHOUSE_SI=${avg_si:='-'}
export LIGHTHOUSE_LCP=${avg_lcp:='-'}
export LIGHTHOUSE_TBT=${avg_tbt:='-'}
export LIGHTHOUSE_CLS=${avg_cls:='-'}
export LIGHTHOUSE_TI=${avg_ti:='-'}
#PR_NUMBER
#GH_TOKEN

## Use teplate and convert
_log info "Loading template"
COMMENT=$(envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < templates/pr_comment_template)
COMMENT="${COMMENT@Q}"
COMMENT="${COMMENT#\$\'}"
COMMENT="${COMMENT%\'}"

## Only post if is in a PR
if [ -n "${PR_NUMBER}" ];
then
    _log info "Posting comment"
    curl --location --request POST "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments" \
        --header "Authorization: token ${GH_TOKEN}" \
        --header "Content-Type: application/json" \
        --data-raw "{\"body\": \"${COMMENT}\"}" \
        --silent -o /dev/null
else
    _log warn "This may not be a PR so not commenting... See full report above"
fi
