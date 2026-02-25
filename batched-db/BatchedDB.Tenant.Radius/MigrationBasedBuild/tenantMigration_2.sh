#!/bin/bash

while read database2; do 

~/sqlpackage/sqlpackage /Action:Publish \
/SourceFile:./bin/Debug/netstandard2.0/model-Tenant.dacpac \
/TargetServerName:${DB_TSN2},1433 \
/TargetDatabaseName:"$database2" \
/TargetUser:${DB_USERNAME2} \
/TargetPassword:${DB_PASSWORD2} \
/DeployScriptPath:"./Result-${BUILD_NUMBER}-2.txt" \
/p:TreatVerificationErrorsAsWarnings=True \
/p:BlockOnPossibleDataLoss=True 
 
done < dblist3
