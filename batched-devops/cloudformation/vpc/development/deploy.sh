#!/bin/bash
aws cloudformation $1 --cli-input-json file://stack-name.json --template-body file://vpc.yml --parameters file://vpc.params.json --region $2