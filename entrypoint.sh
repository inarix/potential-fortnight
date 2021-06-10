#!/bin/bash
if [[ -f .env ]]
then
  export $(grep -v '^#' .env | xargs)
  echo "[$(date +"%m/%d/%y %T")] Exported all env variables"
else 
  echo "[$(date +"%m/%d/%y %T")] An error occured during import .env variables (Reason: no .env file found)"
  exit 1
fi

# Create the KUBECONFIG to be authenticated to cluster
echo "Creation of the KUBECONFIG and connection to the cluster $CLUSTER_NAME"
aws eks --region eu-west-1 update-kubeconfig --name $CLUSTER_NAME

if [[ $? == 1 ]]
then
  echo "[$(date +"%m/%d/%y %T")] An error occured during creation of kubeconfig or connection to cluster $CLUSTER_NAME"
  exit
fi

MODEL_INSTANCE_ID="$INPUT_MODELINSTANCEID"
WORFLOW_TEMPLATE_NAME="$INPUT_WORKFLOWTEMPLATENAME"
REGRESSION_TEST_ID="non-regression-${MODEL_INSTANCE_ID}-$(date +"%s")"

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
echo "[$(date +"%m/%d/%y %T")] Arguments are -p test_id :  $REGRESSION_TEST_ID"
echo "[$(date +"%m/%d/%y %T")] Arguments are -p model_instance_id:  $MODEL_INSTANCE_ID"
echo "[$(date +"%m/%d/%y %T")] Arguments are -p test_file_location_id:  $LOKI_FILE_LOCATION_ID"
echo "[$(date +"%m/%d/%y %T")] Arguments are -p environment: $WORKER_ENV"
echo "::endgroup::"

echo "::group::List Workflows"
argo list
echo "::endgroup::"

echo "::group::Launching ArgoWorkflow"
echo "[$(date +"%m/%d/%y %T")] Launching argo submit --from $WORFLOW_TEMPLATE_NAME -w -p test_id=$REGRESSION_TEST_ID -p model_instance_id=$MODEL_INSTANCE_ID -p test_file_location_id=$LOKI_FILE_LOCATION_ID"
echo "[$(date +"%m/%d/%y %T")] Using $WORKER_ENV environment"

if [[ $WORKER_ENV == "staging" ]]
then
  API_ENDPOINT="staging.api.inarix.com"
  PREDICTION_ENDPOINT="https://${API_ENDPOINT}/imodels/predict"
  echo "[$(date +"%m/%d/%y %T")] Adding arguments inarix_api_hostname: $API_ENDPOINT"
  echo "[$(date +"%m/%d/%y %T")] Adding arguments prediction_entrypoint: $PREDICTION_ENDPOINT"
  WORKFLOW_NAME=$(argo submit --from $WORFLOW_TEMPLATE_NAME -w -p test_id=$REGRESSION_TEST_ID -p model_instance_id=$MODEL_INSTANCE_ID -p test_file_location_id=$LOKI_FILE_LOCATION_ID -p environment=$WORKER_ENV -p inarix_api_hostname=$API_ENDPOINT -p prediction_entrypoint=$PREDICTION_ENDPOINT  -o json | jq -e -r .metadata.name)
elif [[ $WORKER_ENV == "production" ]]
then
  echo "[$(date +"%m/%d/%y %T")] When using env $WORKER_ENV inarix_api_hostname and prediction_entrypoint used are the default ones (created for production purpose)"
  WORKFLOW_NAME=$(argo submit --from $WORFLOW_TEMPLATE_NAME -w -p test_id=$REGRESSION_TEST_ID -p model_instance_id=$MODEL_INSTANCE_ID -p test_file_location_id=$LOKI_FILE_LOCATION_ID -p environment=$WORKER_ENV -o json | jq -e -r .metadata.name)
else
  echo "[$(date +"%m/%d/%y %T")] Error: $WORKER_ENV must be one of [staging, production]"
  exit 1
fi
echo "::endgroup::"

# -- Get Worflow metadata --
echo "::group::Fetching ArgoWorkflow"
argo get $WORKFLOW_NAME
echo "::endgroup::"

# -- Fetch Worflow logs --
echo "::group::Logs ArgoWorkflow"
argo logs $WORKFLOW_NAME --no-color
echo "::endgroup::"

LOGS=$(argo logs $WORKFLOW_NAME --no-color)

LOGS=$(echo $LOGS | while read CMD; do; echo $CMD | cut -d : -f2- ; done;)

# -- Remove line breaker before sending values (Required by GithubAction)  --
LOGS="${LOGS//$'\n'/'%0A'}"
echo "::set-output name=results::'${LOGS}'"

