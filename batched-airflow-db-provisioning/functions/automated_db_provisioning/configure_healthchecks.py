import boto3
import json
import logging
import os
from botocore.exceptions import ClientError
from batched_common.Database import Database
from batched_common.Constants import Constants

# SQS Queue Names (same across all environments)
AGENT_SQS_QUEUE_NAME = 'AgentHeartBeat-HealthCheck.fifo'
ALGOWEB_SQS_QUEUE_NAME = 'AlgoWeb-HealthCheck.fifo'
RULESENGINE_SQS_QUEUE_NAME = 'RulesEngineStep-HealthCheck.fifo'
WORKFLOWJOB_SQS_QUEUE_NAME = 'WorkflowJob-HealthCheck.fifo'

# Scheduler Group Names (consistent across environments)
AGENT_SCHEDULER_GROUP = 'agent-heartbeat-healthcheck-schedules'
ALGOWEB_SCHEDULER_GROUP = 'algoweb-healthcheck-schedules'
RULESENGINE_SCHEDULER_GROUP = 'rules-engine-healthcheck-schedules'
WORKFLOWJOB_SCHEDULER_GROUP = 'workflow-job-healthcheck-schedules'

# EventBridge Scheduler Role Name (same across environments)
SCHEDULER_ROLE_NAME = 'EventBridgeSchedulerToSQSRole'

# Get AWS context from Lambda execution environment
def get_aws_context():
    """Get AWS account ID and region from Lambda execution context"""
    try:
        # Get region from Lambda environment
        region = os.environ.get('AWS_REGION', os.environ.get('AWS_DEFAULT_REGION'))
        
        # Get account ID from STS
        sts_client = boto3.client('sts', region_name=region)
        account_id = sts_client.get_caller_identity()['Account']
        
        logging.info(f"AWS Context - Account: {account_id}, Region: {region}")
        return account_id, region
    except Exception as e:
        logging.error(f"Failed to get AWS context: {e}")
        raise


def build_sqs_arn(queue_name, account_id, region):
    """Build SQS ARN dynamically"""
    return f"arn:aws:sqs:{region}:{account_id}:{queue_name}"


def build_iam_role_arn(role_name, account_id):
    """Build IAM Role ARN dynamically"""
    return f"arn:aws:iam::{account_id}:role/{role_name}"


# Initialize global context
try:
    ACCOUNT_ID, REGION = get_aws_context()
    
    # Build ARNs dynamically
    AGENT_SQS_ARN = build_sqs_arn(AGENT_SQS_QUEUE_NAME, ACCOUNT_ID, REGION)
    ALGOWEB_SQS_ARN = build_sqs_arn(ALGOWEB_SQS_QUEUE_NAME, ACCOUNT_ID, REGION)
    RULESENGINE_SQS_ARN = build_sqs_arn(RULESENGINE_SQS_QUEUE_NAME, ACCOUNT_ID, REGION)
    WORKFLOWJOB_SQS_ARN = build_sqs_arn(WORKFLOWJOB_SQS_QUEUE_NAME, ACCOUNT_ID, REGION)
    SCHEDULER_ROLE_ARN = build_iam_role_arn(SCHEDULER_ROLE_NAME, ACCOUNT_ID)
    
    logging.info(f"Initialized with ARNs for account {ACCOUNT_ID} in region {REGION}")
except Exception as e:
    logging.error(f"Failed to initialize AWS context: {e}")
    ACCOUNT_ID, REGION = None, None
    AGENT_SQS_ARN = None
    ALGOWEB_SQS_ARN = None
    RULESENGINE_SQS_ARN = None
    WORKFLOWJOB_SQS_ARN = None
    SCHEDULER_ROLE_ARN = None

# Initialize scheduler client
scheduler_client = boto3.client('scheduler', region_name=REGION) if REGION else None


def ConfigureHealthChecks(event):
    """
    Configure all 4 types of health check schedules for the newly provisioned tenant
    """
    try:
        # Validate that initialization was successful
        if not ACCOUNT_ID or not REGION:
            raise ValueError("Failed to initialize AWS context. Check Lambda permissions for sts:GetCallerIdentity")
        
        # Extract tenant information from event
        tenant_id = event[Constants.DAGRUNPARAM_TENANTID]
        restore_db_name = event[Constants.DAGRUNPARAM_RESTOREDB]
        
        logging.info(f"Starting health check configuration for tenant_id: {tenant_id} in account: {ACCOUNT_ID}, region: {REGION}")
        
        # Get tenant details from database
        rds = Database()
        tenant_query = f"""
            SELECT t.ID as tenantId, t.Name as tenantName 
            FROM batched.dbo.TenantDatabase td
            JOIN batched.dbo.Tenant t ON td.TenantID = t.ID
            WHERE td.DbName = '{restore_db_name}'
        """
        
        tenant_results = rds.ExecuteReader(tenant_query)
        
        if not tenant_results or len(tenant_results) == 0:
            logging.error(f"Tenant not found for database: {restore_db_name}")
            event['stepsDetails']['stepStatus'] = 'ERROR'
            event['stepsDetails']['NextStep'] = 'Success'
            event['stepsDetails']['errorMessage'] = 'Tenant not found in database'
            return event
        
        tenant_id = tenant_results[0][0]
        tenant_name = tenant_results[0][1]
        
        logging.info(f"Configuring health checks for: {tenant_name} (ID: {tenant_id})")
        
        # Configure schedules
        success_count = 0
        failure_count = 0
        error_messages = []
        
        # 1. Configure Agent HeartBeat Health Check (placeholder)
        # Agents are added manually after tenant provisioning, so we create a disabled placeholder
        logging.info("Creating placeholder agent schedule (agents are added post-provisioning)")
        if create_placeholder_agent_schedule(tenant_name, tenant_id):
            success_count += 1
        else:
            failure_count += 1
            error_messages.append(f"Failed to create placeholder agent schedule for tenant: {tenant_name}")
        
        # 2. Configure AlgoWeb Health Check
        if create_algoweb_schedule(tenant_name, tenant_id):
            success_count += 1
        else:
            failure_count += 1
            error_messages.append(f"Failed to create AlgoWeb schedule for: {tenant_name}")
        
        # 3. Configure Rules Engine Health Check
        if create_rulesengine_schedule(tenant_name, tenant_id):
            success_count += 1
        else:
            failure_count += 1
            error_messages.append(f"Failed to create RulesEngine schedule for: {tenant_name}")
        
        # 4. Configure Workflow Job Health Check
        if create_workflowjob_schedule(tenant_name, tenant_id):
            success_count += 1
        else:
            failure_count += 1
            error_messages.append(f"Failed to create WorkflowJob schedule for: {tenant_name}")
        
        # Update event with results
        logging.info(f"Health check configuration complete. Success: {success_count}, Failures: {failure_count}")
        
        if failure_count == 0:
            event['stepsDetails']['stepStatus'] = 'SUCCESS'
            event['stepsDetails']['NextStep'] = 'Success'
            event['stepsDetails']['healthChecksSummary'] = {
                'total': success_count,
                'successful': success_count,
                'failed': failure_count
            }
        else:
            # Partial success or complete failure
            event['stepsDetails']['stepStatus'] = 'PARTIAL_SUCCESS' if success_count > 0 else 'ERROR'
            event['stepsDetails']['NextStep'] = 'Success'
            event['stepsDetails']['healthChecksSummary'] = {
                'total': success_count + failure_count,
                'successful': success_count,
                'failed': failure_count,
                'errors': error_messages
            }
        
        return event
        
    except Exception as e:
        logging.error(f"Exception while configuring health checks: {str(e)}")
        logging.exception(e)
        event['stepsDetails']['stepStatus'] = 'ERROR'
        event['stepsDetails']['NextStep'] = 'Success'
        event['stepsDetails']['errorMessage'] = str(e)
        return event


def create_placeholder_agent_schedule(tenant_name, tenant_id):
    """
    Create a placeholder agent health check schedule (disabled)
    This schedule is created with empty agent ID and disabled state
    It should be manually updated with actual agent details and enabled when agents are added
    """
    schedule_name = f"agent-hc-{tenant_name}".replace(' ', '-').replace('_', '-')[:64]
    
    message_payload = {
        "agentName": "",  # Empty - to be filled when agent is added
        "agentId": "",    # Empty - to be filled when agent is added
        "tenantId": tenant_id
    }
    
    return _create_schedule(
        schedule_name=schedule_name,
        group_name=AGENT_SCHEDULER_GROUP,
        sqs_arn=AGENT_SQS_ARN,
        message_payload=message_payload,
        message_group_id='agent-healthcheck-group',
        description=f'Placeholder agent health check schedule for tenant {tenant_name} - UPDATE WITH AGENT DETAILS BEFORE ENABLING',
        enabled=False  # Created in disabled state
    )


def create_algoweb_schedule(tenant_name, tenant_id):
    """Create EventBridge schedule for AlgoWeb health check"""
    schedule_name = f"algoweb-hc-{tenant_name}".replace(' ', '-').replace('_', '-')[:64]
    
    message_payload = {
        "tenantName": tenant_name,
        "tenantId": tenant_id
    }
    
    return _create_schedule(
        schedule_name=schedule_name,
        group_name=ALGOWEB_SCHEDULER_GROUP,
        sqs_arn=ALGOWEB_SQS_ARN,
        message_payload=message_payload,
        message_group_id='algoweb-healthcheck-group',
        description=f'AlgoWeb health check schedule for tenant {tenant_name}',
        enabled=True
    )


def create_rulesengine_schedule(tenant_name, tenant_id):
    """Create EventBridge schedule for Rules Engine health check"""
    schedule_name = f"rulesengine-hc-{tenant_name}".replace(' ', '-').replace('_', '-')[:64]
    
    message_payload = {
        "tenantName": tenant_name,
        "tenantId": tenant_id
    }
    
    return _create_schedule(
        schedule_name=schedule_name,
        group_name=RULESENGINE_SCHEDULER_GROUP,
        sqs_arn=RULESENGINE_SQS_ARN,
        message_payload=message_payload,
        message_group_id='rulesengine-healthcheck-group',
        description=f'RulesEngine health check schedule for tenant {tenant_name}',
        enabled=True
    )


def create_workflowjob_schedule(tenant_name, tenant_id):
    """Create EventBridge schedule for Workflow Job health check"""
    schedule_name = f"workflowjob-hc-{tenant_name}".replace(' ', '-').replace('_', '-')[:64]
    
    message_payload = {
        "tenantName": tenant_name,
        "tenantId": tenant_id
    }
    
    return _create_schedule(
        schedule_name=schedule_name,
        group_name=WORKFLOWJOB_SCHEDULER_GROUP,
        sqs_arn=WORKFLOWJOB_SQS_ARN,
        message_payload=message_payload,
        message_group_id='workflowjob-healthcheck-group',
        description=f'WorkflowJob health check schedule for tenant {tenant_name}',
        enabled=True
    )


def _create_schedule(schedule_name, group_name, sqs_arn, message_payload, message_group_id, description, enabled=True):
    """
    Generic function to create or update an EventBridge schedule
    
    Args:
        enabled: If True, schedule is created in ENABLED state. If False, created in DISABLED state.
    """
    schedule_state = 'ENABLED' if enabled else 'DISABLED'
    
    try:
        scheduler_client.create_schedule(
            Name=schedule_name,
            GroupName=group_name,
            ScheduleExpression='cron(0/15 * * * ? *)',  # Every 15 minutes
            FlexibleTimeWindow={'Mode': 'OFF'},
            Target={
                'Arn': sqs_arn,
                'RoleArn': SCHEDULER_ROLE_ARN,
                'Input': json.dumps(message_payload),
                'SqsParameters': {
                    'MessageGroupId': message_group_id
                }
            },
            State=schedule_state,
            Description=description
        )
        status_icon = "✅" if enabled else "⚠️"
        status_text = "ENABLED" if enabled else "DISABLED"
        logging.info(f"{status_icon} Created schedule: {schedule_name} (State: {status_text})")
        return True
        
    except ClientError as e:
        if e.response['Error']['Code'] == 'ConflictException':
            logging.info(f"Schedule {schedule_name} already exists, updating...")
            try:
                scheduler_client.update_schedule(
                    Name=schedule_name,
                    GroupName=group_name,
                    ScheduleExpression='cron(0/15 * * * ? *)',
                    FlexibleTimeWindow={'Mode': 'OFF'},
                    Target={
                        'Arn': sqs_arn,
                        'RoleArn': SCHEDULER_ROLE_ARN,
                        'Input': json.dumps(message_payload),
                        'SqsParameters': {
                            'MessageGroupId': message_group_id
                        }
                    },
                    State=schedule_state,
                    Description=description
                )
                status_icon = "✅" if enabled else "⚠️"
                status_text = "ENABLED" if enabled else "DISABLED"
                logging.info(f"{status_icon} Updated schedule: {schedule_name} (State: {status_text})")
                return True
            except Exception as update_error:
                logging.error(f"❌ Failed to update schedule {schedule_name}: {update_error}")
                return False
        else:
            logging.error(f"❌ Failed to create schedule {schedule_name}: {e}")
            return False
            
    except Exception as e:
        logging.error(f"❌ Unexpected error creating schedule {schedule_name}: {e}")
        return False
