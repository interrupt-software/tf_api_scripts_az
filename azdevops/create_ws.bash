#!/bin/bash

# This script assumes the availability of the following variables:
# TFE_HOST
# TFE_ORG
# TFE_TOKEN
# TFE_WORKSPACE
#

cat << EOF > create_ws.json
{
	"data": {
		"attributes": {
			"name": "$TFE_WORKSPACE"
		},
		"type": "workspaces"
	}
}
EOF

# Call the Terraform API to initialize a new workspace
#
RESPONSE=$(curl -k -s \
  --header "Authorization: Bearer $TFE_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @create_ws.json \
  $TFE_HOST/api/v2/organizations/$TFE_ORG/workspaces)

rm -f create_ws.json

# Use the SUCCESS and ERROR pieces as control variables for this task
# in the pipeline. The task should stop the pipeline on failure.
#
WORKSPACE_ID=$(echo $RESPONSE | jq '.data.id' | tr -d '"')

if [ $WORKSPACE_ID == null ]; then
	SUCCESS=false
	ERROR=$(echo $RESPONSE | jq '.errors[0].detail')
	echo "Error in creating workspace $TFE_WORKSPACE: "$ERROR
else
	SUCCESS=true
fi
