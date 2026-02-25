#!/bin/bash
aws cloudformation $1 --cli-input-json file://stack-name.json --template-body file://security-groups.yml --parameters file://sg.params.json --region $2