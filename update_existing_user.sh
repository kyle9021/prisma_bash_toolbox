#!/bin/bash
# Requires jq to be installed

source ./secrets/secrets

# This will update an existing user. Can be used to unlock an account, change name, timezone, allow access keys, or disable an existing user from the Prisma Cloud Console. 


USER_EMAIL="<EMAIL_ADDRESS_OF_USER>"
USER_FIRSTNAME="<FIRST_NAME_OF_USER>"
USER_LASTNAME="<LAST_NAME_OF_USER>"
# Enables or disables account
ENABLED="<true_or_false>"
# Allows users to create programmatic access keys
KEYS_ALLOWED="<true_or_false>"
# Adjust timezone as you see fit. 
TIME_ZONE="America/Los_Angeles"

AUTH_PAYLOAD_PRE='{"username": "%s", "password": "%s"}'
AUTH_PAYLOAD=$(printf "$AUTH_PAYLOAD_PRE" "$PC_ACCESSKEY" "$PC_SECRETKEY")

PC_JWT=$(curl --request POST \
              --url "$PC_APIURL/login" \
              --header 'Accept: application/json; charset=UTF-8' \
              --header 'Content-Type: application/json; charset=UTF-8' \
              --data "${AUTH_PAYLOAD}" | jq -r '.token')

ROLE_JSON=$(curl --request GET \
                       --url "$PC_APIURL/v2/user/{$USER_EMAIL}" \
                       --header "x-redlock-auth: $PC_JWT")

DEFAULT_ROLE_ID=$(printf %s $ROLE_JSON | jq -r '.defaultRoleId')


declare -a ROLE_ID_ARRAY=$(printf %s $ROLE_JSON | jq -r '.roleIds[]' )

# To add more roles simply add lines under the roleId section with more "%s"
# If you do make sure to add the indexes to the variable ${ROLE_ID_ARRAY[<INDEX_NUMBER_HERE>]} in the $USER_PAYLOAD_VAR

USER_PAYLOAD_PRE='{
  "email": "%s",
  "firstName": "%s",
  "lastName": "%s",
  "enabled": "%s",
  "accessKeysAllowed": "%s",
  "defaultRoleId": "%s",
  "roleIds": [
    "%s"
  ],
  "timeZone": "%s"
}'

USER_PAYLOAD=$(printf "$USER_PAYLOAD_PRE" "$USER_EMAIL" "$USER_FIRSTNAME" "$USER_LASTNAME" "$ENABLED" "$KEYS_ALLOWED" "$DEFAULT_ROLE_ID" "${ROLE_ID_ARRAY[0]}" "$TIME_ZONE" )

curl --request PUT \
  --url https://api3.prismacloud.io/v2/user/{$CTF_USER} \
  --header 'content-type: application/json' \
  --header "x-redlock-auth: $PC_JWT" \
  --data "$USER_PAYLOAD"

exit
