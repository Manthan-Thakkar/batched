#! /bin/bash
aws cloudformation $1 --cli-input-json file://stack-name.json --template-body file://frontend.yml --parameters file://parameter.json --region $2