#!/bin/bash
# written by Kyle Butler

# Pulls all the policies associated with a particular compliance framework in Prisma Cloud

source ./secrets/secrets

# Only variable that needs to be assigned in script
COMPLIANCE_NAME="PCI DSS v3.2.1"


AUTH_PAYLOAD=$(cat <<EOF
{"username": "$PC_ACCESSKEY", "password": "$PC_SECRETKEY"}
EOF
)
REPORT_DATE=$(date  +%m_%d_%y)
POLICY_REPORT_NAME="./Policy_report_$REPORT_DATE.csv"
PC_JWT=$(curl --silent \
              --request POST \
              --url "$PC_APIURL/login" \
              --header 'Accept: application/json; charset=UTF-8' \
              --header 'Content-Type: application/json; charset=UTF-8' \
              --data "$AUTH_PAYLOAD" | jq -r '.token')



POLICY_JSON=$(curl --request GET \
     --url "$PC_APIURL/policy?" \
     --header "x-redlock-auth: $PC_JWT" | jq -r '[.[] | {name: .name, description: .description, cloudtype: .cloudtype, complianceMetadata: .complianceMetadata[]?} | {name: .name, description: .description, cloudtype: .cloudtype, standardName: .complianceMetadata.standardName, standardDescription: .complianceMetadata.standardDescription, requirementId: .complianceMetadata.requirementId, requirementName: .complianceMetadata.requirementName, sectionId: .complianceMetadata.sectionId, sectionDescription: .complianceMetadata.sectionDescription, sectionViewOrder: .complianceMetadata.sectionViewOrder, requirementViewOrder: .complianceMetadata.requirementViewOrder }]'  | jq -r --arg COMPLIANCE_NAME "$COMPLIANCE_NAME" '[.[] | select(.standardName == $COMPLIANCE_NAME)]')

printf %s $POLICY_JSON | jq -r 'map({name, description, cloudtype, standardName, standardDescription, requirementId, requirementName, sectionId, sectionDescription, sectionViewOrder, requirementViewORder}) | (first | keys_unsorted) as $keys | map([to_entries[] | .value]) as $rows | $keys,$rows[] | @csv' > $POLICY_REPORT_NAME

exit
