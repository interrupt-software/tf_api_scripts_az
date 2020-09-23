#!/bin/bash

# This script assumes the availability of the following variables in a Azure
# DevOps variable group:
#
# echo $TFE_HOST
# echo $TFE_ORG
# echo $TFE_TOKEN
# echo $TFE_WORKSPACE
#
# These varables are used throught the entire pipeline run
#
cat << EOF > create_ws.json
{
	"data": {
		"attributes": {
			"name": "$(TFE_WORKSPACE)",
			"auto-apply": "true"
		},
		"type": "workspaces"
	}
}
EOF

# Call the Terraform API to initialize a new workspace.
# In Azure DevOps we need to reference inline pipeline variables using:
# $(VAR) --> $(TFE_TOKEN)
# Whereas typical bash is done like this:
# $VAR --> $VAR
#
RESPONSE=$(curl -k -s \
  --header "Authorization: Bearer $(TFE_TOKEN)" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @create_ws.json \
  $(TFE_HOST)/api/v2/organizations/$(TFE_ORG)/workspaces)

# Clean up as good practice; to ensure nothing is left on
# the worker node
#
rm -f create_ws.json

# Use the SUCCESS and ERROR pieces as control variables for this task
# in the pipeline. The task should stop the pipeline on failure.
#
WORKSPACE_ID=$(echo $RESPONSE | jq '.data.id' | tr -d '"')

if [ $WORKSPACE_ID == null ]; then
	ERROR=$(echo $RESPONSE | jq '.errors[0].detail')
	echo "Error in creating workspace $TFE_WORKSPACE: "$ERROR 1>&2
	exit 1
else
  exit 0
fi
