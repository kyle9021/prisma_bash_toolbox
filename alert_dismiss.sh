#!/bin/bash
# Author Kyle Butler
# Requires jq to be installed on the system you are running the script: https://stedolan.github.io/jq/download/ 

# Instructions to install jq:
# Ubuntu:
# sudo apt-get install jq 
# MacOS: 
# brew install jq
# RHEL
# yum install jq



# Access key should be created in the Prisma Cloud Enterprise Edition Console under: Settings > Accesskeys


source ./secrets/secrets


DISMISS_NOTE="dismissal note here" # your custom note to dismiss
ALERT_ID="2378dbf4-b104-4bda-9b05-7417affbba3f" # alert ID 
POLICY_NAME="AWS Default Security Group does not restrict all traffic" # policy name
TIMEUNIT="year" # minute, hour, day, week, month, year
TIMEAMOUNT="1" # integer value


AUTH_PAYLOAD=$(cat <<EOF
{"username": "$PC_ACCESSKEY", "password": "$PC_SECRETKEY"}
EOF
)


##### NO EDITS BELOW THIS NEEDED #######


PC_JWT=$(curl --silent \
              --request POST \
              --url "$PC_APIURL/login" \
              --header 'Accept: application/json; charset=UTF-8' \
              --header 'Content-Type: application/json; charset=UTF-8' \
              --data "$AUTH_PAYLOAD" | jq -r '.token')



ALERT_PAYLOAD=$(cat <<EOF
{
  "alerts": [],
  "dismissalNote": "$DISMISS_NOTE",
  "dismissalTimeRange": {
    "relativeTimeType": "BACKWARD",
    "type": "relative",
    "value": {
      "amount": "$TIMEAMOUNT",
      "unit": "$TIMEUNIT"
    }
  },
  "filter": {
    "detailed": true,
    "fields": [],
    "filters": [
      {
        "name": "timeRange.type",
        "operator": "=",
        "value": "ALERT_OPENED"
      },
      {
        "name": "alert.status",
        "operator": "=",
        "value": "open"
      },
      {
        "name": "policy.name",
        "operator": "=",
        "value": "$ALERT_ID"
      }
    ],
    "groupBy": [],
    "limit": 0,
    "offset": 0,
    "sortBy": [],
    "timeRange": {
      "relativeTimeType": "BACKWARD",
      "type": "relative",
      "value": {
        "amount": "",
        "unit": ""
      }
    }
  },
  "policies": [
    ""
  ]
}
EOF
)


curl --request POST \
     --url "$PC_APIURL/alert/dismiss" \
     --header 'Accept: application/json, text/plain, */*' \
     --header "x-redlock-auth: $PC_JWT" \
     --header 'Content-Type: application/json' \
     --data "$ALERT_PAYLOAD"


exit
