#!/bin/bash
DB_USERNAME=$1
DB_PASSWORD=$2
sed -i 's!DB_PASSWORD!'${DB_PASSWORD}'!g' rds.params.json
sed -i 's!DB_USERNAME!'${DB_USERNAME}'!g' rds.params.json