#!/bin/bash
# File              : entrypoint.sh
# Author            : Alexandre Saison <alexandre.saison@inarix.com>
# Date              : 28.05.2021
# Last Modified Date: 28.05.2021
# Last Modified By  : Alexandre Saison <alexandre.saison@inarix.com>

MODEL_INSTANCE_ID="$INPUT_MODELINSTANCEID"
MODEL_FILELOC_ID="$INPUT_MODELFILELOCID"
WORFLOW_TEMPLATE_NAME="$INPUT_WORKFLOWTEMPLATENAME"
REGRESSION_TEST_ID="non_regression_$MODEL_INSTANCE_ID_$(date +"%s")"
ARGO_SERVER="$INPUT_ARGOSERVER"

echo "[$(date +"%m/%d/%y %T")] Trying aws-cli"
aws --version
if [[ $? == 1 ]]
then
  echo "[$(date +"%m/%d/%y %T")] Error: AWS CLI check failed"
fi

echo "[$(date +"%m/%d/%y %T")] Trying argo-cli"
argo version
if [[ $? == 1 ]]
then
  echo "[$(date +"%m/%d/%y %T")] Error: Argo CLI check failed"
fi

if [[ -z $MODEL_INSTANCE_ID ]]
then

  echo "[$(date +"%m/%d/%y %T")] Error: missing MODEL_INSTANCE_ID env variable"
  exit 1

elif [[ -z $ARGO_TOKEN ]]
then

  echo "[$(date +"%m/%d/%y %T")] Error: missing ARGO_TOKEN env variable"
  exit 1

elif [[ -z $MODEL_FILELOC_ID ]]
then

  echo "[$(date +"%m/%d/%y %T")] Error: missing MODEL_FILELOC_ID env variable"
  exit 1

elif [[ -z $WORFLOW_TEMPLATE_NAME ]]
then

  echo "[$(date +"%m/%d/%y %T")] Error: missing WORFLOW_TEMPLATE_NAME env variable"
  exit 1

fi

echo "[$(date +"%m/%d/%y %T")] Launching Loki workflow $WORFLOW_TEMPLATE_NAME"

RESPONSE=$(argo submit -s $ARGO_SERVER --token $ARGO_TOKEN --from $WORFLOW_TEMPLATE_NAME  -p test_id=$REGRESSION_TEST_ID -p model_instance_id=$MODEL_INSTANCE_ID -p test_file_location_id=$MODEL_FILELOC_ID)

