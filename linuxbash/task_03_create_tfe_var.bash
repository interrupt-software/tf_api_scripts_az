#!/bin/bash

# This script assumes the availability of the following variables:
# PUBLIC_KEY
#
WORKSPACE_ID=$(curl -k -s \
  --header "Authorization: Bearer $TFE_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  $TFE_HOST/api/v2/organizations/$TFE_ORG/workspaces/$TFE_WORKSPACE \
  | jq '.data.id' \
  | tr -d '"' )

cat << EOF > create_var.json
{
  "data": {
    "type": "vars",
    "attributes": {
      "key": "public_key",
      "value": "$PUBLIC_KEY",
      "category": "terraform",
      "hcl": false,
      "sensitive": true
    },
    "relationships": {
      "workspace": {
        "data": {
          "id": "$WORKSPACE_ID",
          "type": "workspaces"
        }
      }
    }
  }
}
EOF

RESPONSE=$( curl -k -s \
  --header "Authorization: Bearer $TFE_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @create_var.json \
  $TFE_HOST/api/v2/vars )

VARIABLE=$(cat create_var.json | jq '.data.attributes.key' | tr -d '"')

rm -f create_var.json

# Use the SUCCESS and ERROR pieces as control variables for this task
# in the pipeline. The task should stop the pipeline on failure.
#
WORKSPACE_ID=$(echo $RESPONSE | jq '.data.id' | tr -d '"')

if [ $WORKSPACE_ID == null ]; then
	SUCCESS=false
	ERROR=$(echo $RESPONSE | jq '.errors[0].detail')
  echo "Error in creating variable $VARIABLE: "$ERROR
else
	SUCCESS=true
fi
