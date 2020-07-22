WORKSPACE_ID=$(curl -s \
  --header "Authorization: Bearer $(TFE_TOKEN)" \
  --header "Content-Type: application/vnd.api+json" \
  $(TFE_HOST)/api/v2/organizations/$(TFE_ORG)/workspaces/$(TFE_WORKSPACE) \
  | jq '.data.id' \
  | tr -d '"' )

cat << EOF > config_ver.json
{
  "data": {
    "type": "configuration-versions",
    "attributes": {
      "auto-queue-runs": false
    }
  }
}
EOF

UPLOAD_URL=$(curl -s \
  --header "Authorization: Bearer $(TFE_TOKEN)" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @config_ver.json \
  $(TFE_HOST)/api/v2/workspaces/$WORKSPACE_ID/configuration-versions \
  | jq -r '.data.attributes."upload-url"')

UPLOAD_FILE_NAME="infra.tar.gz"
tar -czf $UPLOAD_FILE_NAME -C ../infra --exclude .git .

curl \
  --header "Content-Type: application/octet-stream" \
  --request PUT \
  --data-binary @$UPLOAD_FILE_NAME "$UPLOAD_URL"

cat << EOF > tfe_run.json
{
  "data": {
    "attributes": {
      "is-destroy":false
    },
    "type":"runs",
    "relationships": {
      "workspace": {
        "data": {
          "type": "workspaces",
          "id": "$WORKSPACE_ID"
        }
      }
    }
  }
}
EOF

RESULT=$(curl -s \
  --header "Authorization: Bearer $(TFE_TOKEN)" \
  --header "Content-Type: application/vnd.api+json" \
  --data @tfe_run.json \
  $(TFE_HOST)/api/v2/runs)

RUN_ID=$(echo  $RESULT | jq '.data.id' | tr -d '"')

RUNNING=1
SUCCESS=false

while [ $RUNNING -ne 0 ]; do
  RUN_STATUS=$(curl -s \
    --header "Authorization: Bearer $(TFE_TOKEN)" \
    --header "Content-Type: application/vnd.api+json" \
    $(TFE_HOST)/api/v2/runs/$RUN_ID \
    | jq '.data.attributes.status' \
    | tr -d '"' )

  if [[ $RUN_STATUS == "planned_and_finished" ]] || [[ $RUN_STATUS == "applied" ]]; then
    RUNNING=0
    SUCCESS=true
    echo -ne "$(date) $RUN_STATUS ------------------------\r"
  elif [[ $RUN_STATUS == "errored" ]]; then
    RUNNING=0
    SUCCESS=false
    echo -ne "$(date) $RUN_STATUS ------------------------\r"
  fi

  if [ $RUNNING -ne 0 ]; then
    for i in {1..5}; do
      echo -ne "$(date) $RUN_STATUS ------------------------\r"
      sleep 1
    done
  fi

  echo ""

done

rm -f $UPLOAD_FILE_NAME
rm -f config_ver.json
rm -f tfe_run.json

unset UPLOAD_FILE_NAME
unset UPLOAD_URL
unset RESULT

echo "Done! SUCCESS is "$SUCCESS
