# Provisioning Steps

- **Step 1:** Edit the vpc.params.json and stack-name.json file and include the necessary parameters.
For more details refer IP Addressing in Your VPC: https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/vpc-ip-addressing.html

- **Step 2:** Execute the following command `sh deploy.script create-stack <region>` or `sh deploy.script update-stack <region>`
  (Here create-stack is for new setups and update-stack for changes)

## Command details for CloudFormation

- To create stack execute `sh deploy.sh create-stack <region>`
- To update stack execute `sh deploy.sh update-stack <region>`
 
## Development
You can verify the cloudformation template while developing using the following command `sh validate.sh`