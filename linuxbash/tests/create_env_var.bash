#!/bin/bash

display_usage() {
	echo -e "Name\n\t$0"
  echo -e "\nDescription\n\t"
  echo -e "Makes an API call to your Terraform Enterprise, or Terraform Cloud"
  echo -e "environment to create a variable in a workspace. This script assumes"
  echo -e "that the pipeline process is able to access the following variables:"
  echo -e "\n\tTFE HOST: Where Terraform Enterprise or Terraform Cloud is hosted."
  echo -e "\tTFE ORG: Your TFE/C organization."
  echo -e "\tTFE_TOKEN: Your personal access TFE/C token."
  echo -e "\tTFE_WORKSPACE: The desired workspace in your TFE/C organization."
  echo -e "\nArguments\n\t<name> <value> [env | terraform] [true | false]\n"
  echo -e "\tNAME: Name of the variable"
  echo -e "\tVALUE: Value of the variable"
  echo -e "\tCAT: Category for the variable; either \"env\" or \"terraform\". Defaults to \"env\"."
  echo -e "\tSENSITIVE: Visibility for the variable; either \"true\" or \"false\". Defaults to \"true\"."
  echo -e "\nExample:\n\t$0 ARM_CLIENT_SECRET \$ARM_CLIENT_SECRET env true"
  echo -e "\t$0 ARM_CLIENT_SECRET \$ARM_CLIENT_SECRET\n"
	}

function push_variable {
  # $1 - Variable name
  # $2 - Variable value
  # $3 - Should be category: env or terraform
  # $4 - Should be sensitivity: true or false
  #
  # In this scenario we are using
  # Workspace ID (should be global)

  CATEGORY=env
  SENSITIVE=true

  if [ "$3" != "" ]; then
    CATEGORY=$3
  fi

  if [ "$4" != "" ]; then
    SENSITIVE=$4
  fi

  # Create payload template. Note that we are marking these as sensitive
  cat << EOF > create_var.json
  {
    "data": {
      "type": "vars",
      "attributes": {
        "key": "$1",
        "value": "$2",
        "category": "$CATEGORY",
        "hcl": false,
        "sensitive": $SENSITIVE
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

  # Call the Terraform API to create a new variable. We should have a second
  # call to update a variable but it has to be a deliberate action.
  RESPONSE=$( curl -k -s \
    --header "Authorization: Bearer $TFE_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    --request POST \
    --data @create_var.json \
    $TFE_HOST/api/v2/vars )

  # The following command is here for test and control
  # echo $RESPONSE >&1
  #
  # Clean up as good practice; to ensure nothing is left on
  # the worker node
  #
  rm -f create_var.json

  WORKSPACE_ID=$(echo $RESPONSE | jq '.data.id' | tr -d '"')

  # Use the SUCCESS and ERROR pieces as control variables for this task
  # in the pipeline. The task should stop the pipeline on failure.
  #
  if [ $WORKSPACE_ID == null ]; then
    TITLE=$(echo $RESPONSE | jq '.errors[0].title')
  	ERROR=$(echo $RESPONSE | jq '.errors[0].detail')
    echo "Error in creating variable $1: "$TITLE": "$ERROR 2>&1
    exit 1
  else
    exit 0
  fi

}

# We use the global WORKSPACE_ID variable to start the work.
#
WORKSPACE_ID=$(curl -k -s \
  --header "Authorization: Bearer $TFE_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  $TFE_HOST/api/v2/organizations/$TFE_ORG/workspaces/$TFE_WORKSPACE \
  | jq '.data.id' \
  | tr -d '"' )

# if less than two arguments supplied, display usage
  if [  $# -le 1 ]
  then
  	display_usage
  	exit 1
  elif [ $# -eq 2 ]
  then
    # Push the variable
    push_variable $1 $2
  elif [ $# -eq 3 ]
  then
    # Push the variable
    push_variable $1 $2 $3
  elif [ $# -eq 4 ]
  then
    # Push the variable
    push_variable $1 $2 $3 $4
  fi
