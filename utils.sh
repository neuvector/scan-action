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