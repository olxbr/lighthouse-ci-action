#/bin/bash

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
COMMENT=$(envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < templates/pr_comment_template)
COMMENT="${COMMENT@Q}"
COMMENT="${COMMENT#\$\'}"
COMMENT="${COMMENT%\'}"

if [ -n "${PR_NUMBER}" ];
then
    curl --location --request POST "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments" \
        --header "Authorization: token ${GH_TOKEN}" \
        --header "Content-Type: application/json" \
        --data-raw "{\"body\": \"${COMMENT}\"}" \
        --silent
else
    echo "Not commenting on PR :) see full report above"
fi
