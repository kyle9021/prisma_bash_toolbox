#!/bin/sh

source ./secrets/secrets

#Put container image tag here
IMAGE_TAG="swaggerapi/petstore:latest"

LEARNING_PAYLOAD=$(cat <<EOF
{"state":"manualLearning"}
EOF
)


# Retrieves the IMAGE PROFILE ID from the compute console
# self-hosted may require curl -k depending on if you're using a self-signed cert
PROFILE_ID=$(curl -X GET \
                  -u $TL_USER:$TL_PASSWORD \
                  --url "$TL_CONSOLE/api/v1/profiles/container?search=$IMAGE_TAG" | jq -r '.[]._id')

# Turns on the learning mode for the container image
# self-hosted may require curl -k depending on if you're using a self-signed cert
curl -X POST \
     -u $TL_USER:$TL_PASSWORD \
     --url "$TL_CONSOLE/api/v1/profiles/container/$PROFILE_ID/learn" \
     -H "Content-Type: application/json" \
     -d $LEARNING_PAYLOAD
