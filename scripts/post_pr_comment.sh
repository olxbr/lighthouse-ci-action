#/bin/bash

source scripts/utils.sh

# Lhci Configs
export COLLECT_PRESET=${LHCI_COLLECT__SETTINGS__PRESET:-mobile}

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
#PR_NUMBER
#GH_TOKEN

TEMPLATE="templates/pr_comment_template"

function _check_for_comments () {
    _log info "Checking for past comments"
    COMMENTS=$(curl --location --request GET "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments?per_page=100" \
            --header "Authorization: token ${GH_TOKEN}" \
            --silent)
    LAST_COMMENT_ID=$(jq -c '.[] | select(.body | test("'"^${HEADER}"'")) | select(.user.login == "olxbr-bot") .id' <<< ${COMMENTS} | tail -n1)
    if [ -n "${LAST_COMMENT_ID}" ];
    then
        _log info "Found past comments, deleting it..."
        curl --location --request DELETE "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/comments/${LAST_COMMENT_ID}" \
            --header "Authorization: token ${GH_TOKEN}" \
            --silent -o /dev/null || _log warn "Got an error during deletion of ${LAST_COMMENT_ID}! This may be a Token issue!"
    else
        _log info "There is no old comments of this action in the PR!"
    fi
}

function _post_comment () {
    _log info "Posting comment"
    curl --location --request POST "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments" \
        --header "Authorization: token ${GH_TOKEN}" \
        --header "Content-Type: application/json" \
        --data-raw "{\"body\": \"${COMMENT}\"}" \
        --silent -o /dev/null
}

## Use teplate and convert
_log info "Loading template"
COMMENT=$(envsubst "$(printf '${%s} ' $(env | cut -d'=' -f1))" < ${TEMPLATE})

## Getting header after variable substitution
HEADER=$(echo "${COMMENT}" | head -n1 | sed 's/[\(\)]/\\\\&/g')

COMMENT="${COMMENT@Q}"
COMMENT="${COMMENT#\$\'}"
COMMENT="${COMMENT%\'}"

## Only post if is in a PR
if [ -n "${PR_NUMBER}" ];
then
    _check_for_comments
    _post_comment
else
    _log warn "This may not be a PR so not commenting... See full report above"
fi
