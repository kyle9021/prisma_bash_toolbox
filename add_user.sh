#!/bin/bash
# Requires jq to be installed


source ./secrets/secrets


# Username information. The goal here is to pull this information and assign to a these variables using a different api call. 
PC_USER_FIRSTNAME="<FIRSTNAME>"
PC_USER_LASTNAME="<LASTNAME>"
PC_USER_ROLE="<PUT_THE_NAME_OF_THE_USER_ROLE_HERE>"
PC_USER_EMAIL="<EMAIL_HERE>"
PC_USER_TIMEZONE="America/New_York"
PC_USER_KEY_EXPIRATION_DATE="0"
PC_USER_ACCESSKEY_ALLOW="true"
PC_USER_ACCESSKEY_NAME="$PC_USER_FIRSTNAME accesskey"
PC_USER_KEY_EXPIRATION="false"
PC_USERNAME="$PC_USER_EMAIL"



AUTH_PAYLOAD_PRE='{"username": "%s", "password": "%s"}'
AUTH_PAYLOAD=$(printf "$AUTH_PAYLOAD_PRE" "$PC_ACCESSKEY" "$PC_SECRETKEY")


PC_JWT=$(curl --request POST \
              --url "$PC_APIURL/login" \
              --header 'Accept: application/json; charset=UTF-8' \
              --header 'Content-Type: application/json; charset=UTF-8' \
              --data "${AUTH_PAYLOAD}" | jq -r '.token')


PC_USER_ROLES=$(curl --request GET \
	             --url "$PC_APIURL/user/role" \
                     --header "x-redlock-auth: ${PC_JWT}")

PC_USER_ROLE_ID=$(printf %s "${PC_USER_ROLES}" | jq '.[] | {id: .id, name: .name}' | jq -r '.name, .id'| awk "/""${PC_USER_ROLE}""/{getline;print}")

PC_ROLE_PAYLOAD_PRE='{
  "accessKeyExpiration": "%s",
  "accessKeyName": "%s",
  "accessKeysAllowed": "%s",
  "defaultRoleId": "%s",
  "email": "%s",
  "enableKeyExpiration": "%s",
  "firstName": "%s",
  "lastName": "%s",
  "roleIds": [
    "%s"
  ],
  "timeZone": "%s",
  "type": "USER_ACCOUNT",
  "username": "%s"
}'

PC_ROLE_PAYLOAD=$(printf "$PC_ROLE_PAYLOAD_PRE" "$PC_USER_KEY_EXPIRATION_DATE" "$PC_USER_ACCESSKEY_NAME" "$PC_USER_ACCESSKEY_ALLOW" "$PC_USER_ROLE" "$PC_USER_EMAIL" "$PC_USER_KEY_EXPIRATION" "$PC_USER_FIRSTNAME" "$PC_USER_LASTNAME" "$PC_USER_ROLE_ID" "$PC_USER_TIMEZONE" "$PC_USERNAME")

# This adds the new user
curl --request POST \
     --url "$PC_APIURL/v2/user" \
     --header "Content-Type: application/json" \
     --header "x-redlock-auth: ${PC_JWT}" \
     --data-raw "$PC_ROLE_PAYLOAD"



exit
