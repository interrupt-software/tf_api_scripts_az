export WORKSPACE_ID=$(curl -k \
  --header "Authorization: Bearer $(TFE_TOKEN)" \
  --header "Content-Type: application/vnd.api+json" \
  $(TFE_HOST)/api/v2/organizations/$(TFE_ORG)/workspaces/$(TFE_WORKSPACE) \
  | jq '.data.id' \
  | tr -d '"' )

cat << EOF >>  create_var1.json
{
  "data": {
    "type": "vars",
    "attributes": {
      "key": "ARM_SUBSCRIPTION_ID",
      "value": "$(ARM_SUBSCRIPTION_ID)",
      "category": "env",
      "hcl": false,
      "sensitive": false
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
  --header "Authorization: Bearer $(TFE_TOKEN)" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @create_var1.json \
  $(TFE_HOST)/api/v2/vars


cat << EOF >>  create_var2.json
{
  "data": {
    "type": "vars",
    "attributes": {
      "key": "ARM_CLIENT_SECRET",
      "value": "$(ARM_CLIENT_SECRET)",
      "category": "env",
      "hcl": false,
      "sensitive": false
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
  --header "Authorization: Bearer $(TFE_TOKEN)" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @create_var2.json \
  $(TFE_HOST)/api/v2/vars


cat << EOF >>  create_var3.json
{
  "data": {
    "type": "vars",
    "attributes": {
      "key": "ARM_TENANT_ID",
      "value": "$(ARM_TENANT_ID)",
      "category": "env",
      "hcl": false,
      "sensitive": false
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
  --header "Authorization: Bearer $(TFE_TOKEN)" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @create_var3.json \
  $(TFE_HOST)/api/v2/vars

cat << EOF >>  create_var4.json
{
  "data": {
    "type": "vars",
    "attributes": {
      "key": "ARM_CLIENT_ID",
      "value": "$(ARM_CLIENT_ID)",
      "category": "env",
      "hcl": false,
      "sensitive": false
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
  --header "Authorization: Bearer $(TFE_TOKEN)" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @create_var4.json \
  $(TFE_HOST)/api/v2/vars

rm -f create_var1.json
rm -f create_var2.json
rm -f create_var3.json
rm -f create_var4.json
