# potential-fortnight
Auto generated name for Loki integration tests run as Argo workflow

**WARNING**: Since This github action is the logical following ``bookish-happiness`` Github Action, It is required to launch this one in a ``mt-exported-XXX`` repo with a ``.env``

## Inputs

### > `modelInstanceId`
Id of the registered model that has been deployed to ArgoCD. Required since this is a paramater for the ```argo submit``` command in the entrypoint.sh


### > `argoServer` (Optionnal)
Endpoint of the ArgoWorflow server (default: argo.inarix.com)


### > `workflowTemplateName` (Optionnal)
Name of the Argo WorflowTemplate to launch.(default: workflowtemplate/wt-model-deploy-non-regression)

## Outputs

### > `results`

String representation of the Workflow results

## Example usage
```yaml
- name: Argo model deployment
  id: deploy_model
  uses: inarix/bookish-happiness@v1
- name: Loki integration
  id: loki_integration_tests
  uses: inarix/potential-fortnight@v1
  with:
    modelInstanceId: ${{ steps.deploy_model.outputs.modelInstanceId }}
```

## How to create Github action

First create a folder **.github/workflows** then create a new YAML file called with the name of the Job you want to create.

For example you can create ```.github/workflows/main.yaml```
```yaml
name: Deploy model on ArgoCD
on: pull_request
jobs:
  deploy-model:
    name: ArgoCD model deployment 
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Argo model deployment
          id: deploy_model
          uses: inarix/bookish-happiness@v1
      - name: Loki integration
          id: loki_integration_tests
          uses: inarix/potential-fortnight@v1
          with:
          modelInstanceId: ${{ steps.deploy_model.outputs.modelInstanceId }}
      - name: comment PR
        uses: unsplash/comment-on-pr@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          DEPLOYED_MODEL_ID: ${{ steps.deploy_model.outputs.modelInstanceId }}
          LOKI_RESULTS: ${{ steps.loki_integration_tests.outputs.results }}
        with:
          msg: 'Deployed exported model (id: $DEPLOYED_MODEL_ID): $LOKI_RESULTS'
          check_for_duplicate_msg: false
```

This will create a Github Action on each update (push, rebase ...) in a pull request.

NB: You need to always add ```- uses: actions/checkout@v2``` for the github action to fetch your code !