#!/bin/bash
aws cloudformation $1 --cli-input-json file://stack-name.json --template-body file://efs.yml --parameters file://efs.params.json --region $2