#!/bin/bash

a="$(Release.DefinitionName)"
b="$(Release.ReleaseName)"
TFE_WORKSPACE=${a// /_}"-"${b// /_}
echo "##vso[task.setvariable variable=TFE_WORKSPACE;isSecret=false;isOutput=true;]$TFE_WORKSPACE"

cat << EOF > create_ws.json
{
	"data": {
		"attributes": {
			"name": "$TFE_WORKSPACE",
			"auto-apply": "true"
		},
		"type": "workspaces"
	}
}
EOF

WORKSPACE_ID=$(curl -k -s \
  --header "Authorization: Bearer $(TFE_TOKEN)" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @create_ws.json \
  $(TFE_HOST)/api/v2/organizations/$(TFE_ORG)/workspaces)

cat << EOF > create_var1.json
{
  "data": {
    "type": "vars",
    "attributes": {
      "key": "ARM_SUBSCRIPTION_ID",
      "value": "$(ARM_SUBSCRIPTION_ID)",
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
  --header "Authorization: Bearer $(TFE_TOKEN)" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @create_var1.json \
  https://$(TFE_HOST)/api/v2/vars )

cat << EOF >  create_var2.json
{
  "data": {
    "type": "vars",
    "attributes": {
      "key": "ARM_CLIENT_SECRET",
      "value": "$(ARM_CLIENT_SECRET)",
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
  --header "Authorization: Bearer $(TFE_TOKEN)" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @create_var2.json \
  https://$(TFE_HOST)/api/v2/vars


cat << EOF > create_var3.json
{
  "data": {
    "type": "vars",
    "attributes": {
      "key": "ARM_TENANT_ID",
      "value": "$(ARM_TENANT_ID)",
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
  --header "Authorization: Bearer $(TFE_TOKEN)" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @create_var3.json \
  https://$(TFE_HOST)/api/v2/vars

cat << EOF > create_var4.json
{
  "data": {
    "type": "vars",
    "attributes": {
      "key": "ARM_CLIENT_ID",
      "value": "$(ARM_CLIENT_ID)",
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
  --header "Authorization: Bearer $(TFE_TOKEN)" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @create_var4.json \
  https://$(TFE_HOST)/api/v2/vars

rm -f create_var1.json
rm -f create_var2.json
rm -f create_var3.json
rm -f create_var4.json
