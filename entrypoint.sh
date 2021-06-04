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
aws sts get-caller-identity
aws eks --region eu-west-1 update-kubeconfig --name $CLUSTER_NAME

MODEL_INSTANCE_ID="$INPUT_MODELINSTANCEID"
WORFLOW_TEMPLATE_NAME="$INPUT_WORKFLOWTEMPLATENAME"
REGRESSION_TEST_ID="non_regression_${MODEL_INSTANCE_ID}_$(date +"%s")"
ARGO_SERVER="$INPUT_ARGOSERVER"

if [[ -z $MODEL_INSTANCE_ID ]]
then

  echo "[$(date +"%m/%d/%y %T")] Error: missing MODEL_INSTANCE_ID env variable"
  exit 1

elif [[ -z $ARGO_TOKEN ]]
then

  echo "[$(date +"%m/%d/%y %T")] Error: missing ARGO_TOKEN env variable"
  exit 1

elif [[ -z $WORFLOW_TEMPLATE_NAME ]]
then

  echo "[$(date +"%m/%d/%y %T")] Error: missing WORFLOW_TEMPLATE_NAME env variable"
  exit 1

fi

echo "[$(date +"%m/%d/%y %T")] Launching Loki workflow $WORFLOW_TEMPLATE_NAME"
echo "[$(date +"%m/%d/%y %T")] Arguments are -s :  $ARGO_SERVER"
echo "[$(date +"%m/%d/%y %T")] Arguments are -p test_id :  $REGRESSION_TEST_ID"
echo "[$(date +"%m/%d/%y %T")] Arguments are -p model_instance_id:  $MODEL_INSTANCE_ID"
echo "[$(date +"%m/%d/%y %T")] Arguments are -p test_file_location_id:  $LOKI_FILE_LOCATION_ID"

RESPONSE=$(argo submit -s $ARGO_SERVER --token $ARGO_TOKEN --from $WORFLOW_TEMPLATE_NAME  -p test_id=$REGRESSION_TEST_ID -p model_instance_id=$MODEL_INSTANCE_ID -p test_file_location_id=$LOKI_FILE_LOCATION_ID)
# -- Get Worflow metadata --
# argo get hello-world-xxx        

# -- Fetch Worflow logs --
#LOGS=$(argo logs hello-world-xxx)

# -- Remove line breaker before sending values (Required by GithubAction)  --
#LOGS="${LOGS//$'\n'/'%0A'}"
echo "::set-output name=results::'toto'"

