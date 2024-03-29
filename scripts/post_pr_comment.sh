#/bin/bash

## Load common functions
source scripts/utils.sh

function _check_for_comments () {
    _log info "Checking for past comments"
    COMMENTS=$(curl --location --request GET "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments?per_page=100" \
            --header "Authorization: token ${GH_TOKEN}" \
            --silent)
    ## Is a valid response ?
    [[ -z "$(jq -r '.[].body' <<< $COMMENTS 2> /dev/null)" ]] &&
        _log warn "Can't find comments in the repository. Maybe there isn't any comment or the API is out or blocked by rate-limit. Skipping process to check comment." &&
        _log warn "CMD: curl --location --request GET https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments?per_page=100" &&
        _log warn "BODY: ${COMMENTS}" &&
        return

    LAST_COMMENT_ID=$(jq -c '.[] | select(.body | test("'"^${HEADER}"'")) | .id' <<< ${COMMENTS} | tail -n1)
    if [ -n "${LAST_COMMENT_ID}" ];
    then
        _log info "Found past comments id [${LAST_COMMENT_ID}], deleting it..."
        HTTP_RESPONSE=$(curl --location --request DELETE "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/comments/${LAST_COMMENT_ID}" \
            --header "Authorization: token ${GH_TOKEN}" \
            --silent -o delete.response \
            --write-out '%{http_code}' || _log warn "Got an error during deletion of ${LAST_COMMENT_ID}! This may be a Token issue!")

        [[ "${HTTP_RESPONSE}" =~ ^20 ]] &&
            _log info "Deleted! HTTP status was [${HTTP_RESPONSE}]" ||
            _log warn "Can't delete comment id [${LAST_COMMENT_ID}] on PR Number [${PR_NUMBER}]. HTTP status was [${HTTP_RESPONSE}] and response body was [$(cat delete.response)]"
    else
        _log info "There is no old comments of this action in the PR!"
    fi
}

function _post_comment () {
    _log info "Posting comment..."
    HTTP_RESPONSE=$(curl --location --request POST "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments" \
        --header "Authorization: token ${GH_TOKEN}" \
        --header "Content-Type: application/json" \
        --data-raw "{\"body\": \"${COMMENT}\"}" \
        --silent -o post.response \
        --write-out '%{http_code}')

    [[ "${HTTP_RESPONSE}" =~ ^20 ]] &&
        _log info "Posted! HTTP status was [${HTTP_RESPONSE}]" ||
        _log warn "Can't post comment on PR Number [${PR_NUMBER}]. HTTP status was [${HTTP_RESPONSE}], response body was [$(cat post.response)] and resquest body was [${COMMENT}]"
}

## Create comment
if ${COMMENT_ON_PR}; then
    _log info "Creating comment on PR..."
else
    _log info "No comments to do!"
    exit 0
fi

urls=$(jq '.[].url' <<< $aggregate_reports)

for url in $urls; do

    ## Export all summary/metrics values to ENV
    jq -r ".[] | select(.url==$url) | .summary | keys[] as \$k | \"export \(\$k)='\(.[\$k])'\"" <<< $aggregate_reports > export.sh && source export.sh

    # Link do Json
    lighthouse_link=$(jq -r ".[] | select(.url==$url) | .link" <<< $aggregate_reports)

    export score_comparation_desc=$([[ "$COMPARATION_WAS_EXECUTED" == true ]] && echo '(Difference between previous)' || echo '')

    # Lhci Configs
    export COLLECT_PRESET=${LHCI_COLLECT__SETTINGS__PRESET:-mobile}

    # Evaluating env vars to use in templates
    export EVALUATED_URL=" - ${url//\"/}"
    export EVALUATED_LIGHTHOUSE_LINK=$([ -n "$lighthouse_link" ] && echo "> _For full web report see [this page](${lighthouse_link})._")

    export U_TIME=$(jq -r ".[] | select(.url==$url) | .numericUnit" <<< $aggregate_reports)
    export PERFORMANCE_COLOR=$(_badge_color "${performance}")
    export ACESSIBILITY_COLOR=$(_badge_color "${accessibility}")
    export BP_COLOR=$(_badge_color "${bestPractices}")
    export SEO_COLOR=$(_badge_color "${seo}")
    export PWA_COLOR=$(_badge_color "${pwa}")

    # To Escape URI encode
    jq -r ".[] | select(.url==$url) | .summary | keys[] as \$k | \"export \(\$k)='\(.[\$k])'\"" <<< $aggregate_reports | sed -E s,%,%25,g > export.sh &&
        sed -i -E s,\ ,%20,g export.sh &&
        sed -i -E 's,\-,˗,g' export.sh &&
        sed -i -E 's,export%20,export ,g' export.sh &&
        source export.sh
    jq -r ".[] | select(.url==$url) | .metrics | keys[] as \$k | \"export \(\$k)='\(.[\$k])'\"" <<< $aggregate_reports > export.sh && source export.sh

    ## Use template and convert
    _log info "Loading template"
    TEMPLATE="templates/pr_comment_template"
    COMMENT=$(envsubst < ${TEMPLATE})

    ## Escape newlines to 1 line for comments (JSON)
    COMMENT="${COMMENT//$'\n'/\\n}"

    ## Getting header after variable substitution and escaping as necessary
    HEADER="${COMMENT%%\\n*}\n" ## Just Title
    HEADER=${HEADER//\?/.}      ## Escape querystring
    HEADER=${HEADER//[()]/.}    ## Escape parenthesis

    ## Only post if is in a PR and github token was filled in
    if [ -n "${PR_NUMBER}" ];
    then
        [ -z "${GH_TOKEN}" ] &&
            _log warn "There is NO GH_TOKEN found to comment on PR. Skipping this process." &&
            exit 0

        _check_for_comments
        _post_comment
    else
        _log warn "This may not be a PR so not commenting... See full report above"
        _log info "If you want a comment in the PR, you need to add/enable the 'pull_request' event in the workflow file [${GITHUB_WORKFLOW_REF%@*}]"
        _log info ""
        _log info "┌─────"
        _log info "| name: ${GITHUB_WORKFLOW}"
        _log info "| on:"
        _log info "|   ${C_WHT}- pull_request${C_END} ## Important to comment on PR (lighthouse)"
        break
    fi
done