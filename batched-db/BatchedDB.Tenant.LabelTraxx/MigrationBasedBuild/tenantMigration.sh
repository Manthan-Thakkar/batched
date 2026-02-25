#!/bin/bash

while read database; do 

~/sqlpackage/sqlpackage /Action:Publish \
/SourceFile:./bin/Debug/netstandard2.0/model-Tenant.dacpac \
/TargetServerName:${DB_TSN},1433 \
/TargetDatabaseName:"$database" \
/TargetUser:${DB_USERNAME} \
/TargetPassword:${DB_PASSWORD} \
/DeployScriptPath:"./Result-${BUILD_NUMBER}.txt" \
/p:TreatVerificationErrorsAsWarnings=True \
/p:BlockOnPossibleDataLoss=True 
 
done < DBLIST