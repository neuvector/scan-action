#!/usr/bin/env bash

function filterOutExemptCVEsFromJson() {
    local scanResult="$1"
    local exemptCVEsJson="$2"

    local filterJson="$(cat "$scanResult")"

    # Filter out the exempted CVEs from the top-level vulnerabilities array
    filterJson=$(jq --argjson exemptions "$exemptCVEsJson" '
        .report.vulnerabilities |= map(select(.name as $name | $exemptions | index($name) | not))
    ' <<<"$filterJson")

    # Filter out the exempted CVEs from the cves array in each module
    filterJson=$(jq --argjson exemptions "$exemptCVEsJson" '
        .report.modules |= map(
            if .cves then 
                .cves |= map(select(.name as $name | $exemptions | index($name) | not)) 
            else 
                . 
            end
        )
    ' <<<"$filterJson")

    if [ -n "$filterJson" ]; then
        echo "$filterJson" > "$scanResult"
    else    
        echo "Error: Filtered Scan result JSON is empty. The original file will not be modified."
        exit 1
    fi
}

send_get_request() {
    local registryUsername="$1"
    local registryPassword="$2"
    local registryURL="$3"
    local endpoint="$4"
    curl -s -u "$registryUsername:$registryPassword" "$registryURL$endpoint"
}

# Function to list repositories
list_repositories() {
    local registryUsername="$1"
    local registryPassword="$2"
    local registryURL="$3"
    local endpoint="/repositories/$registryUsername/"
    send_get_request "$registryUsername" "$registryPassword" "$registryURL" "$endpoint" | jq -r '.results[].name'
}

# Function to list tags for a repository
list_tags() {
    local registryUsername="$1"
    local registryPassword="$2"
    local registryURL="$3"
    local repository="$4"
    local endpoint="/repositories/$registryUsername/$repository/tags"
    send_get_request "$registryUsername" "$registryPassword" "$registryURL" "$endpoint" | jq -r '.results[].name'
}

# Function to get all repositories with tags
get_all_repositories_with_tags_all() {
    local registryUsername="$1"
    local registryPassword="$2"
    local registryURL="https://hub.docker.com/v2"
    local repos=$(list_repositories "$registryUsername" "$registryPassword" "$registryURL")
    local repo_set=()

    for repo in $repos; do
        local tags=$(list_tags "$registryUsername" "$registryPassword" "$registryURL" "$repo")
        for tag in $tags; do
            repo_set+=("$repo:$tag")
        done
    done

    echo "${repo_set[@]}"
}

        
# Repository will be formulated to "{username}/{repository}".
# If the username is empty, consider it a public registry and add "library/" prefix.
# If the input already contains a "/", we consider it already formulated.
function prepareRepository() {
    local registryUsername="$1"
    local registryPassword="$2"
    local currentRepo="$3"
    local tag="$4"
    local repo_set
    local formulateRepository="$3"

    # Capture the output of the function into a variable
    repo_set=$(get_all_repositories_with_tags_all "$registryUsername" "$registryPassword")

    if [[ -n "$registryUsername" ]]; then
        # Extract the base name of the currentRepo (i.e., the last part after the last '/')
        local repoBaseName=$(basename "$currentRepo")

        # Check if the repository:tag combination exists in the repo_set array
        if [[ " ${repo_set[@]} " =~ " $repoBaseName:$tag " ]]; then
            formulateRepository="$registryUsername/$repoBaseName"
        else
            formulateRepository="library/$repoBaseName"
        fi
    fi

    echo "$formulateRepository"
}