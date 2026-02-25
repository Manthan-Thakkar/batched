# Batched Secret Rotation Lambdas

This repository contains two AWS SAM packages:

- `lt-batched-integration-rotation/` — two Lambda functions deployed via a single SAM template.
- `rds-mssql-rotation/` — two Lambda functions for RDS MSSQL Secret Rotation:
  - `rotate-master-password` — handles rotation steps.
  - `finish-secret-update-params` — invoked in finish step to update parameters.

Quick start (from each subfolder):
- sam build -u
- sam deploy --guided

Note: Templates include minimal scaffolding. Add policies, environment variables, triggers, and resources as needed before deployment.
