#! /bin/bash
aws cloudformation $1 --cli-input-json file://stack-name.json --template-body file://main.yml --parameters file://parameters.json --region $2