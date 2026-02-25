#!/bin/bash
aws cloudformation $1 --cli-input-json file://stack-name.json --template-body file://rds.yml --parameters file://rds.params.json --region $2