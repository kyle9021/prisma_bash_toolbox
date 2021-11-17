#!/bin/bash
#------------------------------------------------------------------------------------------------------------------#
# Written By Kyle Butler
#
# REQUIREMENTS: 
# Requires jq to be installed: 'sudo apt-get install jq'
#
# SET-UP:
# Create Access Key and Secret Key in the Prisma Cloud Console
# Access keys and Secret keys are created in the Prisma Cloud Console under: Settings > Access Keys
# Find the Prisma Cloud Enterprise Edition API URL specific to your deployment: https://prisma.pan.dev/api/cloud/api-url
#
# SECURITY RECOMMENDATIONS:

source ./secrets/secrets

### Warning #### This report will take a while to run. Ensure you're using a machine that has plenty of HDD space, CPU, and RAM to process all the data that will be returned. 

#### This will pull all the alerts by the policy ids associated to the compliance framework and export everything as a CSV. 

# comes from the console
COMPLIANCE_NAME="CIS v1.4.0 (AWS)"
TIME_TYPE="relative"
TIME_UNIT="month"
TIME_AMOUNT="1"
STATUS="open"

AUTH_PAYLOAD=$(cat <<EOF
{"username": "$PC_ACCESSKEY", "password": "$PC_SECRETKEY"}
EOF
)
REPORT_DATE=$(date  +%m_%d_%y)

PC_JWT=$(curl --silent \
              --request POST \
              --url "$PC_APIURL/login" \
              --header 'Accept: application/json; charset=UTF-8' \
              --header 'Content-Type: application/json; charset=UTF-8' \
              --data "$AUTH_PAYLOAD" | jq -r '.token')


COMPLIANCE_ID=$(curl --request GET \
                     --url "$PC_APIURL/compliance" \
                     --header "x-redlock-auth: $PC_JWT" | jq -r --arg COMPLIANCE_NAME "$COMPLIANCE_NAME" '.[] | select(.name == $COMPLIANCE_NAME) | .id')


SECTION_ID=$(curl --request GET \
                  --url "$PC_APIURL/compliance/{$COMPLIANCE_ID}/requirement" \
                  --header "x-redlock-auth: $PC_JWT" | jq -r '.[].id')

declare -a SECTION_ID_ARRAY=($(printf %s "$SECTION_ID"))

COMPLIANCE_SECTION_RESPONSE=$(for SECTION_ID in "${SECTION_ID_ARRAY[@]}"; do
                                    curl --request GET \
			                 --url $PC_APIURL/compliance/{$SECTION_ID}/section \
			                 --header "x-redlock-auth: $PC_JWT" | jq '.[]';
                              done)    


POLICY_ID_ARRAY=($(printf %s "$COMPLIANCE_SECTION_RESPONSE" | jq -r '.associatedPolicyIds[]'))


for POLICY_ID in ${POLICY_ID_ARRAY[@]}; do 
	          curl --request GET \
                       --url "$PC_APIURL/v2/alert?timeType=$TIME_TYPE&timeAmount=$TIME_AMOUNT&timeUnit=$TIME_UNIT&detailed=true&policy.id=$POLICY_ID&status=$STATUS" \
		       --header "x-redlock-auth: $PC_JWT" | jq --arg COMPLIANCE_NAME "$COMPLIANCE_NAME" '.items[] | select(.status == "open") | {standardName: .policy.complianceMetadata[].standardName, requirementId: .policy.complianceMetadata[].requirementId, sectionId: .policy.complianceMetadata[].sectionId, account: .resource.account, resourceName: .resource.name, resourceType: .resource.resourceType, url: .resource.url, tagKey: .resource.data.tags[].key, tagValue: .resource.data.tags[].value, policyName: .policy.name, policyDescription: .policy.description} | select(.standardName == $COMPLIANCE_NAME)' | jq -r '[.] | map({standardName, requirementId, sectionId, account, resourceName, resourceType, url, tagKey, tagValue, policyName, policyDescription}) | (first | keys_unsorted) as $keys | map([to_entries[] | .value]) as $rows | $rows[] | @csv' >> ./detailed_compliance_alert_report_$REPORT_DATE.csv
done 

exit
