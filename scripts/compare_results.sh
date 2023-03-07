#/bin/bash

## Load common functions
source ${ACTION_PATH}/scripts/utils.sh

## Declare env variables
branch_to_compare=${BRANCH_TO_COMPARE}

[[ $branch_to_compare == 'none' ]] && 
    _log warn "No branches were used to compare. Nothing to do, finished!" &&
    exit 0

_log "Branch [$branch_to_compare] has been configured to compare results"
git fetch --force --tags
git checkout $branch_to_compare

ls -l