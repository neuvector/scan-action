#!/usr/bin/env bash

set -e

REGISTRY_ARG=""

if [ -n "${SCANNER_REGISTRY}" ]; then
  REGISTRY_ARG="-e SCANNER_REGISTRY=${SCANNER_REGISTRY}"
fi
if [ -n "${SCANNER_REGISTRY_USERNAME}" ]; then
  REGISTRY_ARG="${REGISTRY_ARG} -e SCANNER_REGISTRY_USERNAME=${SCANNER_REGISTRY_USERNAME}"
fi
if [ -n "${SCANNER_REGISTRY_PASSWORD}" ]; then
  REGISTRY_ARG="${REGISTRY_ARG} -e SCANNER_REGISTRY_PASSWORD=${SCANNER_REGISTRY_PASSWORD}"
fi

NV_SCANNER_IMAGE=${NV_SCANNER_IMAGE:-"neuvector/scanner:latest"}
HIGH_VUL_TO_FAIL=${HIGH_VUL_TO_FAIL:-"0"}
MEDIUM_VUL_TO_FAIL=${MEDIUM_VUL_TO_FAIL:-"0"}
OUTPUT=${OUTPUT:-"text"}
DEBUG=${DEBUG:-"false"}

docker run --name neuvector.scanner ${REGISTRY_ARG} -e SCANNER_REPOSITORY=${SCANNER_REPOSITORY} -e SCANNER_TAG=${SCANNER_TAG} -e SCANNER_ON_DEMAND=true -v /var/run/docker.sock:/var/run/docker.sock ${NV_SCANNER_IMAGE} > scanner_output.log
result=$?

if [ ${result} -ne 0 ]; then
  cat scanner_output.log
  exit ${result}
fi

if [[ ${DEBUG} == "true" ]]; then
  cat scanner_output.log;
fi

docker cp neuvector.scanner:/var/neuvector/scan_result.json scan_result.json
docker rm neuvector.scanner

VUL_NUM=$(cat scan_result.json | jq '.report.vulnerabilities | length')
FOUND_HIGH=$(cat scan_result.json | jq '.report.vulnerabilities[] | select(.severity == "High") | .severity' | wc -l)
FOUND_MEDIUM=$(cat scan_result.json | jq '.report.vulnerabilities[] | select(.severity == "Medium") | .severity' | wc -l)
VUL_LIST=$(printf '["%s"]' "${VUL_NAMES_TO_FAIL//,/\",\"}")
VUL_LIST_FOUND=$(cat scan_result.json | jq --arg arr "$VUL_LIST" '.report.vulnerabilities[] | select(.name as $n | $arr | index($n)) |.name')

echo "vulnerability_count=${VUL_NUM}" >> $GITHUB_OUTPUT
echo "high_vulnerability_count=${FOUND_HIGH}" >> $GITHUB_OUTPUT
echo "medium_vulnerability_count=${FOUND_MEDIUM}" >> $GITHUB_OUTPUT

if [[ -n $VUL_LIST_FOUND ]]; then
  fail_reason="Found specific named vulnerabilities."
  scan_fail="true"
elif [ ${HIGH_VUL_TO_FAIL} -ne 0 -a $FOUND_HIGH -ge ${HIGH_VUL_TO_FAIL} ]; then
  fail_reason="Found ${FOUND_HIGH} high vulnerabilities exceeding the maximum of ${HIGH_VUL_TO_FAIL}."
  scan_fail="true"
elif [ ${MEDIUM_VUL_TO_FAIL} -ne 0 -a $FOUND_MEDIUM -ge ${MEDIUM_VUL_TO_FAIL} ]; then
  fail_reason="Found ${MEDIUM_VUL_TO_FAIL} medium vulnerabilities exceeding the maximum of ${MEDIUM_VUL_TO_FAIL}."
  scan_fail="true"
else
  fail_reason=""
  scan_fail="false"
fi

if [[ $scan_fail == "true" ]]; then
  summary="Image scanning failed. ${fail_reason}"
else
  summary="Image scanning succeed."
fi

if [[ "$OUTPUT" == "text" ]]; then
  echo -e "NeuVector scan result for ${SCANNER_REGISTRY}${SCANNER_REPOSITORY}:${SCANNER_TAG}\n"

  if [ ${VUL_NUM} -eq 0 ]; then
    echo "No vulnerabilities found."
  else
    echo "Total number of vulnerabilities, $VUL_NUM"
  fi

  if [ -z "$VUL_LIST_FOUND" ]; then
    echo -e "Found High Vulnerabilities = $FOUND_HIGH \nFound Medium Vulnerabilities = $FOUND_MEDIUM \n"
  else
    echo -e "Found specific named vulnerabilities: \n$VUL_LIST_FOUND \n\nHigh Vulnerabilities threshold = ${HIGH_VUL_TO_FAIL} \nFound High Vulnerabilities = $FOUND_HIGH \n\nMedium vulnerabilities threshold = ${MEDIUM_VUL_TO_FAIL}\nFound Medium Vulnerabilities = $FOUND_MEDIUM \n"
  fi

  echo -e "Vulnerabilities grouped by packages:\n"

  jq -r '[.report.vulnerabilities | group_by(.package_name) | .[] | {package_name: .[0].package_name, vuls: [ (.[] | {name: .name, description: .description, severity: .severity}) ]}] | .[] | (.package_name) + ":\n" +  (.vuls | [.[] | .name + " (" + .severity + "): " + .description] | join("\n")) + "\n\n"' scan_result.json

  echo -e "\n${summary}"
fi

if [[ "$OUTPUT" == "json" ]]; then
  cat scan_result.json
fi

if [[ "$OUTPUT" == "csv" ]]; then
  labels='"name","score","severity","description","package_name","package_version","fixed_version","link","published_timestamp","last_modified_timestamp"'
  vars=".name,.score,.severity,.description,.package_name,.package_version,.fixed_version,.link,.published_timestamp,.last_modified_timestamp"
  query='"report".vulnerabilities[]'

  cat scan_result.json | jq -r '['$labels'],(.'$query' | ['$vars'])|@csv'
fi

if [[ "$scan_fail" == "true" ]]; then
  exit 1;
fi
