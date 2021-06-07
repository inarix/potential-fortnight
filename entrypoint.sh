#!/bin/bash
if [[ -f .env ]]
then
  export $(grep -v '^#' .env | xargs)
  echo "[$(date +"%m/%d/%y %T")] Exported all env variables"
else 
  echo "[$(date +"%m/%d/%y %T")] An error occured during import .env variables"
  exit 1
fi

# Create the KUBECONFIG to be authenticated to cluster
echo "Creation of the KUBECONFIG and connection to the cluster $CLUSTER_NAME"
aws eks --region eu-west-1 update-kubeconfig --name $CLUSTER_NAME

MODEL_INSTANCE_ID="$INPUT_MODELINSTANCEID"
WORFLOW_TEMPLATE_NAME="$INPUT_WORKFLOWTEMPLATENAME"
REGRESSION_TEST_ID="non-regression-${MODEL_INSTANCE_ID}-$(date +"%s")"
ARGO_SERVER="$INPUT_ARGOSERVER"

if [[ -z $MODEL_INSTANCE_ID ]]
then

  echo "[$(date +"%m/%d/%y %T")] Error: missing MODEL_INSTANCE_ID env variable"
  exit 1

elif [[ -z $WORFLOW_TEMPLATE_NAME ]]
then

  echo "[$(date +"%m/%d/%y %T")] Error: missing WORFLOW_TEMPLATE_NAME env variable"
  exit 1

fi

echo "::group::Argo arguments list"
echo "[$(date +"%m/%d/%y %T")] Launching Loki workflow $WORFLOW_TEMPLATE_NAME"
echo "[$(date +"%m/%d/%y %T")] Arguments are -s :  $ARGO_SERVER"
echo "[$(date +"%m/%d/%y %T")] Arguments are -p test_id :  $REGRESSION_TEST_ID"
echo "[$(date +"%m/%d/%y %T")] Arguments are -p model_instance_id:  $MODEL_INSTANCE_ID"
echo "[$(date +"%m/%d/%y %T")] Arguments are -p test_file_location_id:  $LOKI_FILE_LOCATION_ID"
echo "::endgroup::"

echo "Fetching list of current Argo Workflow."
echo "::group::List Workflows"
argo list
echo "::endgroup::"

echo "::group::Launching ArgoWorkflow"
echo "Launching argo submit --from $WORFLOW_TEMPLATE_NAME -w -p test_id=$REGRESSION_TEST_ID -p model_instance_id=$MODEL_INSTANCE_ID -p test_file_location_id=$LOKI_FILE_LOCATION_ID"
WORKFLOW_NAME=$(argo submit --from $WORFLOW_TEMPLATE_NAME -w  -p test_id=$REGRESSION_TEST_ID -p model_instance_id=$MODEL_INSTANCE_ID -p test_file_location_id=$LOKI_FILE_LOCATION_ID -o json | jq -e -r .metadata.name)
echo "::endgroup::"

# -- Get Worflow metadata --
echo "::group::Fetching ArgoWorkflow"
argo get $WORKFLOW_NAME
echo "::endgroup::"

# -- Fetch Worflow logs --
echo "::group::Logs ArgoWorkflow"
argo logs $WORKFLOW_NAME
echo "::endgroup::"

LOGS=$(argo logs $WORKFLOW_NAME)

# -- Remove line breaker before sending values (Required by GithubAction)  --
LOGS="${LOGS//$'\n'/'%0A'}"
echo "::set-output name=results::'${LOGS}'"

