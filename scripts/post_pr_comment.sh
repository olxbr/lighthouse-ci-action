#/bin/bash

export LIGHTHOUSE_LINK=${lighthouse_link:='https://github.com/olxbr/lighthouse-ci-action'}
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
#GHA_TOKEN

COMMENT=$(envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < templates/pr_comment_template)

#curl --location --request POST 'https://api.github.com/repos/olxbr/${GITHUB_REPOSITORY}/pulls/${PR_NUMBER}/replies' \
#    --header 'Authorization: token ${GHA_TOKEN}' \
#    --header 'Content-Type: application/json' \
#    --data-raw '{"body": "${COMMENT@Q}"}'

echo "${COMMENT@Q}"
