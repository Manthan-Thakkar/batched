# S3 BUCKETS DEPLOYMENT

**Step 1:** Edit the _s3-buckets-params.json_ and file to match the new environment domain. Also edit _stack-name.json_ accordingly by updating the domain name, and stage (dev|qa|stg|prod).
**Step 2:** Execute the following command `sh deploy.sh create-stack {REGION}` or `sh deploy.sh update-stack {REGION}`
  (Here create-stack is for new setups and update-stack for changes)

## Command deails for CloudFormation

To create the stack, execute:
>sh deploy.sh create-stack __\{REGION\}__

To update the stack, execute:
>sh deploy.sh update-stack __\{REGION\}__

## Development
You can verify the cloudformation template while developing using the following command `sh validate.sh`