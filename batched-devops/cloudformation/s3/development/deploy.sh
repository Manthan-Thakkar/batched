#! /bin/bash
aws cloudformation $1 --cli-input-json file://stack-name.json --template-body file://s3-buckets.yml --parameters file://s3-buckets-params.json --region $2