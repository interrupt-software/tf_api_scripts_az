#!/bin/bash

WORKSPACE_ID=$(curl -k -s \
  --header "Authorization: Bearer $TFE_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  $TFE_HOST/api/v2/organizations/$TFE_ORG/workspaces/$TFE_WORKSPACE \
  | jq '.data.id' \
  | tr -d '"' )

cat << EOF > create_var1.json
{
  "data": {
    "type": "vars",
    "attributes": {
      "key": "ARM_SUBSCRIPTION_ID",
      "value": "$ARM_SUBSCRIPTION_ID",
      "category": "env",
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
  --data @create_var1.json \
  $TFE_HOST/api/v2/vars )

# VARIABLE=$(cat create_var.json | jq '.data.attributes.key' | tr -d '"')
#
# # Use the SUCCESS and ERROR pieces as control variables for this task
# # in the pipeline. The task should stop the pipeline on failure.
# #
# WORKSPACE_ID=$(echo $RESPONSE | jq '.data.id' | tr -d '"')
#
# if [ $WORKSPACE_ID == null ]; then
# 	SUCCESS=false
# 	ERROR=$(echo $RESPONSE | jq '.errors[0].detail')
# else
# 	SUCCESS=true
# fi

rm -f create_var.json

cat << EOF >  create_var2.json
{
  "data": {
    "type": "vars",
    "attributes": {
      "key": "ARM_CLIENT_SECRET",
      "value": "$ARM_CLIENT_SECRET",
      "category": "env",
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

curl -k -s \
  --header "Authorization: Bearer $TFE_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @create_var2.json \
  $TFE_HOST/api/v2/vars


cat << EOF > create_var3.json
{
  "data": {
    "type": "vars",
    "attributes": {
      "key": "ARM_TENANT_ID",
      "value": "$ARM_TENANT_ID",
      "category": "env",
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

curl -k -s \
  --header "Authorization: Bearer $TFE_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @create_var3.json \
  $TFE_HOST/api/v2/vars

cat << EOF > create_var4.json
{
  "data": {
    "type": "vars",
    "attributes": {
      "key": "ARM_CLIENT_ID",
      "value": "$ARM_CLIENT_ID",
      "category": "env",
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

curl -k \
  --header "Authorization: Bearer $TFE_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @create_var4.json \
  $TFE_HOST/api/v2/vars

rm -f create_var1.json
rm -f create_var2.json
rm -f create_var3.json
rm -f create_var4.json
