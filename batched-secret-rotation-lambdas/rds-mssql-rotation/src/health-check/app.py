import json
import boto3
import logging
import os
import time
import requests
from datetime import datetime
from typing import Dict, List, Tuple
import concurrent.futures
import threading

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """Comprehensive health check Lambda with retry logic and SNS notifications.
    
    Expected event:
    {
        "trigger": "secret_rotation_completed",
        "timestamp": 1234567890
    }
    """
    
    try:
        trigger = event.get('trigger', 'unknown')
        timestamp = event.get('timestamp', time.time())
        
        logger.info(f"Starting comprehensive health check triggered by: {trigger}")
        
        # Perform comprehensive health checks with retries
        health_check_results = perform_comprehensive_health_checks()
        
        # Analyze results
        failed_checks = [result for result in health_check_results if not result['success']]
        
        if failed_checks:
            # Send SNS notification for failures
            send_failure_notification(failed_checks, trigger)
            
            return {
                'statusCode': 500,
                'body': json.dumps({
                    'message': 'Health checks failed',
                    'failed_checks': failed_checks,
                    'total_checks': len(health_check_results),
                    'trigger': trigger
                })
            }
        else:
            logger.info("All health checks passed successfully")
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'All health checks passed',
                    'total_checks': len(health_check_results),
                    'trigger': trigger
                })
            }
            
    except Exception as e:
        logger.error(f"Health check Lambda failed: {e}", exc_info=True)
        
        # Send SNS notification for Lambda failure
        send_lambda_failure_notification(str(e), event)
        
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def perform_comprehensive_health_checks() -> List[Dict]:
    """Perform health checks for all configured endpoints in parallel with retry logic"""
    
    # Define health check configurations
    health_check_configs = get_health_check_configs()
    
    logger.info(f"Starting {len(health_check_configs)} health checks in parallel")
    
    results = []
    
    # Run health checks in parallel using ThreadPoolExecutor
    with concurrent.futures.ThreadPoolExecutor(max_workers=min(len(health_check_configs), 10)) as executor:
        # Submit all health check tasks
        future_to_config = {
            executor.submit(perform_single_health_check_with_retry, config): config 
            for config in health_check_configs
        }
        
        # Collect results as they complete
        for future in concurrent.futures.as_completed(future_to_config):
            config = future_to_config[future]
            try:
                result = future.result()
                results.append(result)
                
                # Log completion
                if result['success']:
                    logger.info(f"✅ Health check '{config['name']}' completed successfully")
                else:
                    logger.error(f"❌ Health check '{config['name']}' failed after retries")
                    
            except Exception as e:
                logger.error(f"Health check '{config['name']}' threw exception: {e}")
                # Create error result for exceptions
                result = {
                    'name': config['name'],
                    'success': False,
                    'error': f"Exception during health check: {str(e)}",
                    'exception': True
                }
                
                # Add appropriate identifier
                check_type = config.get('type', 'http')
                if check_type == 'lambda':
                    result['function_name'] = config.get('function_name', 'N/A')
                else:
                    result['url'] = config.get('url', 'N/A')
                
                results.append(result)
    
    logger.info(f"Completed all {len(results)} health checks")
    return results

def get_health_check_configs() -> List[Dict]:
    """Fetch health check configurations from Parameter Store"""
    
    try:
        # Get the parameter name from environment variable
        param_name = os.environ.get('HEALTH_CHECK_CONFIG_PARAMETER', '/secret-rotation/health-check-config')
        
        ssm = boto3.client('ssm')
        
        logger.info(f"Fetching health check configuration from parameter: {param_name}")
        
        response = ssm.get_parameter(
            Name=param_name,
            WithDecryption=True  # In case the parameter contains sensitive data
        )
        
        config_json = response['Parameter']['Value']
        configs = json.loads(config_json)
        
        logger.info(f"Successfully loaded {len(configs)} health check configurations")
        
        # Validate configuration structure
        for i, config in enumerate(configs):
            # All configs need a name
            if 'name' not in config:
                error_msg = f"Health check config {i} missing required field: name"
                logger.error(error_msg)
                send_configuration_error_notification(error_msg, param_name)
                raise ValueError(error_msg)
            
            # Check if it's a Lambda or HTTP health check
            check_type = config.get('type', 'http')  # Default to HTTP if type not specified
            
            if check_type == 'lambda':
                # Lambda health checks require function_name
                if 'function_name' not in config:
                    error_msg = f"Lambda health check config {i} ('{config['name']}') missing required field: function_name"
                    logger.error(error_msg)
                    send_configuration_error_notification(error_msg, param_name)
                    raise ValueError(error_msg)
            else:
                # HTTP health checks require url
                if 'url' not in config:
                    error_msg = f"HTTP health check config {i} ('{config['name']}') missing required field: url"
                    logger.error(error_msg)
                    send_configuration_error_notification(error_msg, param_name)
                    raise ValueError(error_msg)
            
            # Set default values for optional fields
            config.setdefault('method', 'GET')
            config.setdefault('timeout', 30)
            config.setdefault('expected_status', 200)
            config.setdefault('headers', {})
            # Note: retry_delay is now fixed at 30 seconds in perform_single_health_check_with_retry
        
        return configs
        
    except ssm.exceptions.ParameterNotFound:
        error_msg = f"Health check configuration parameter '{param_name}' not found in Parameter Store"
        logger.error(error_msg)
        send_configuration_error_notification(error_msg, param_name)
        raise ValueError(error_msg)
    
    except json.JSONDecodeError as e:
        error_msg = f"Failed to parse health check configuration JSON: {e}"
        logger.error(error_msg)
        send_configuration_error_notification(error_msg, param_name)
        raise ValueError(error_msg)
    
    except Exception as e:
        error_msg = f"Failed to fetch health check configuration from Parameter Store: {e}"
        logger.error(error_msg)
        send_configuration_error_notification(error_msg, param_name)
        raise ValueError(error_msg)

def send_configuration_error_notification(error_message: str, parameter_name: str):
    """Send SNS notification for health check configuration errors"""
    
    sns_topic_arn = os.environ.get('HEALTH_CHECK_SNS_TOPIC')
    
    if not sns_topic_arn:
        logger.warning("SNS topic ARN not configured for health check notifications")
        return
    
    try:
        sns = boto3.client('sns')
        
        subject = "🚨 Health Check Configuration Error"
        
        message = f"""
Health Check Configuration Error Detected

Error: {error_message}
Parameter: {parameter_name}
Timestamp: {datetime.utcnow().isoformat()}Z
Lambda: SecretRotationHealthCheck

This is a CRITICAL error that prevents health checks from running after secret rotation.
Please fix the configuration immediately to ensure proper monitoring.

Required Actions:
1. Check Parameter Store for the health check configuration
2. Validate JSON format and required fields
3. Ensure all health checks have proper configuration

Health Check Requirements:
- HTTP checks: must have 'name' and 'url' fields
- Lambda checks: must have 'name', 'type': 'lambda', and 'function_name' fields
"""
        
        response = sns.publish(
            TopicArn=sns_topic_arn,
            Subject=subject,
            Message=message.strip()
        )
        
        logger.info(f"Configuration error notification sent to SNS. MessageId: {response['MessageId']}")
        
    except Exception as e:
        logger.error(f"Failed to send configuration error notification to SNS: {e}")

def perform_single_health_check_with_retry(config: Dict) -> Dict:
    """Perform a single health check with exactly 2 retries and immediate SNS alerts on failure
    
    Retry behavior:
    - Initial attempt (attempt 0)
    - If failed, wait 30 seconds, then retry (attempt 1) 
    - If failed again, wait 30 seconds, then retry (attempt 2)
    - Total: 3 attempts with 30-second delays between failures
    """
    
    max_retries = 2
    retry_delay_seconds = 30  # Fixed 30-second delay as requested
    result = None
    
    for attempt in range(max_retries + 1):  # 0, 1, 2 (initial + 2 retries)
        try:
            if attempt > 0:
                logger.info(f"🔄 Retry {attempt} for health check '{config['name']}' - waiting {retry_delay_seconds} seconds before retry...")
                time.sleep(retry_delay_seconds)
                logger.info(f"🔄 Starting retry {attempt} for health check '{config['name']}'")
            
            result = perform_single_health_check(config)
            
            if result['success']:
                if attempt > 0:
                    logger.info(f"✅ Health check '{config['name']}' succeeded on retry {attempt}")
                return result
            else:
                logger.warning(f"❌ Health check '{config['name']}' failed on attempt {attempt + 1}")
            
        except Exception as e:
            logger.error(f"❌ Health check '{config['name']}' attempt {attempt + 1} threw exception: {e}")
            
            # Create error result with appropriate identifier
            check_type = config.get('type', 'http')
            if check_type == 'lambda':
                identifier = config.get('function_name', 'N/A')
                identifier_key = 'function_name'
            else:
                identifier = config.get('url', 'N/A')
                identifier_key = 'url'
            
            result = {
                'name': config['name'],
                'success': False,
                'error': str(e),
                'attempt': attempt + 1,
                'exception': True,
                identifier_key: identifier
            }
            
            # If this wasn't the last attempt, we'll retry after delay
            if attempt < max_retries:
                logger.warning(f"⏳ Will retry health check '{config['name']}' after {retry_delay_seconds} seconds...")
    
    # All attempts failed - send immediate SNS notification
    logger.error(f"🚨 Health check '{config['name']}' failed after {max_retries + 1} attempts (with {retry_delay_seconds}s delays) - sending immediate alert")
    
    # Send immediate SNS notification for this specific failed health check
    send_individual_health_check_failure_notification(result, config)
    
    return result

def perform_single_health_check(config: Dict) -> Dict:
    """Perform a single health check attempt"""
    
    check_type = config.get('type', 'http')  # Default to HTTP if type not specified
    
    if check_type == 'lambda':
        return perform_lambda_health_check(config)
    else:
        return perform_http_health_check(config)

def perform_lambda_health_check(config: Dict) -> Dict:
    """Perform health check by invoking a Lambda function"""
    
    name = config['name']
    function_name = config['function_name']
    timeout = config.get('timeout', 60)
    payload = config.get('payload', {})
    expected_response = config.get('expected_response', {})
    
    logger.info(f"Performing Lambda health check: {name} -> {function_name}")
    
    try:
        # Create Lambda client
        lambda_client = boto3.client('lambda')
        
        # Invoke the Lambda function
        response = lambda_client.invoke(
            FunctionName=function_name,
            InvocationType='RequestResponse',  # Synchronous invocation
            Payload=json.dumps(payload)
        )
        
        # Parse the response
        response_payload = json.loads(response['Payload'].read().decode('utf-8'))
        status_code = response.get('StatusCode', 0)
        
        # Check if invocation was successful
        if status_code != 200:
            raise Exception(f"Lambda invocation failed with status code: {status_code}")
        
        # Check for function errors
        if 'FunctionError' in response:
            error_type = response['FunctionError']
            raise Exception(f"Lambda function error ({error_type}): {response_payload}")
        
        # Validate response against expected response if provided
        success = True
        validation_errors = []
        
        if expected_response:
            if isinstance(expected_response, str):
                # Simple string comparison for responses like "success"
                if isinstance(response_payload, str):
                    success = response_payload == expected_response
                    if not success:
                        validation_errors.append(f"Expected '{expected_response}', got '{response_payload}'")
                else:
                    # Check if it's a JSON response with a string value
                    response_str = json.dumps(response_payload) if isinstance(response_payload, (dict, list)) else str(response_payload)
                    success = response_str == expected_response
                    if not success:
                        validation_errors.append(f"Expected string '{expected_response}', got {type(response_payload).__name__}: {response_payload}")
            else:
                # Complex object validation
                success, validation_errors = validate_lambda_response(response_payload, expected_response)
        
        result = {
            'name': name,
            'success': success,
            'function_name': function_name,
            'status_code': status_code,
            'response': response_payload,
            'validation_errors': validation_errors if validation_errors else None
        }
        
        if success:
            logger.info(f"Lambda health check {name} passed")
        else:
            logger.warning(f"Lambda health check {name} failed validation: {validation_errors}")
        
        return result
        
    except Exception as e:
        logger.error(f"Lambda health check {name} failed: {e}")
        return {
            'name': name,
            'success': False,
            'error': str(e),
            'function_name': function_name
        }

def validate_lambda_response(actual_response: Dict, expected_response: Dict) -> tuple[bool, List[str]]:
    """Validate Lambda response against expected response"""
    
    errors = []
    
    def compare_values(actual, expected, path=""):
        if isinstance(expected, dict):
            if not isinstance(actual, dict):
                errors.append(f"Expected dict at {path}, got {type(actual).__name__}")
                return
            
            for key, expected_value in expected.items():
                current_path = f"{path}.{key}" if path else key
                
                if key not in actual:
                    errors.append(f"Missing key: {current_path}")
                    continue
                
                # Special handling for wildcard values
                if expected_value == "*":
                    continue  # Accept any value
                
                compare_values(actual[key], expected_value, current_path)
        
        elif isinstance(expected, list):
            if not isinstance(actual, list):
                errors.append(f"Expected list at {path}, got {type(actual).__name__}")
                return
            
            if len(actual) != len(expected):
                errors.append(f"List length mismatch at {path}: expected {len(expected)}, got {len(actual)}")
                return
            
            for i, (actual_item, expected_item) in enumerate(zip(actual, expected)):
                compare_values(actual_item, expected_item, f"{path}[{i}]")
        
        else:
            if actual != expected:
                errors.append(f"Value mismatch at {path}: expected {expected}, got {actual}")
    
    try:
        compare_values(actual_response, expected_response)
        return len(errors) == 0, errors
    except Exception as e:
        return False, [f"Validation error: {str(e)}"]

def perform_http_health_check(config: Dict) -> Dict:
    """Perform HTTP-based health check"""
    
    name = config['name']
    url = config['url']
    method = config.get('method', 'GET')
    timeout = config.get('timeout', 30)
    expected_status = config.get('expected_status', 200)
    headers = config.get('headers', {})
    
    logger.info(f"Performing HTTP health check: {name} -> {url}")
    
    try:
        if method.upper() == 'GET':
            response = requests.get(url, headers=headers, timeout=timeout)
        elif method.upper() == 'POST':
            response = requests.post(url, headers=headers, timeout=timeout, json=config.get('payload', {}))
        else:
            raise ValueError(f"Unsupported HTTP method: {method}")
        
        success = response.status_code == expected_status
        
        result = {
            'name': name,
            'success': success,
            'status_code': response.status_code,
            'expected_status': expected_status,
            'url': url,
            'response_time_ms': response.elapsed.total_seconds() * 1000
        }
        
        if success:
            logger.info(f"Health check {name} passed: {response.status_code}")
        else:
            logger.warning(f"Health check {name} failed: expected {expected_status}, got {response.status_code}")
            result['error'] = f"Status code mismatch: expected {expected_status}, got {response.status_code}"
            result['response_text'] = response.text[:500]  # First 500 chars for debugging
        
        return result
        
    except requests.exceptions.Timeout:
        error = f"Health check {name} timed out after {timeout}s"
        logger.error(error)
        return {
            'name': name,
            'success': False,
            'error': error,
            'url': url
        }
    
    except requests.exceptions.ConnectionError as e:
        error = f"Health check {name} connection failed: {str(e)}"
        logger.error(error)
        return {
            'name': name,
            'success': False,
            'error': error,
            'url': url
        }
    
    except Exception as e:
        error = f"Health check {name} failed: {str(e)}"
        logger.error(error)
        return {
            'name': name,
            'success': False,
            'error': error,
            'url': url
        }

def send_individual_health_check_failure_notification(result: Dict, config: Dict):
    """Send immediate SNS notification for individual health check failure"""
    
    try:
        sns_topic_arn = os.environ.get('HEALTH_CHECK_SNS_TOPIC')
        if not sns_topic_arn:
            logger.warning("HEALTH_CHECK_SNS_TOPIC not configured, skipping individual failure notification")
            return
        
        sns = boto3.client('sns')
        
        # Determine check type and identifier
        check_type = config.get('type', 'http')
        if check_type == 'lambda':
            identifier = f"Lambda Function: {config.get('function_name', 'Unknown')}"
        else:
            identifier = f"URL: {config.get('url', 'Unknown')}"
        
        subject = f"🚨 URGENT: Health Check Failed After Retries - {result['name']}"
        
        message = f"""
URGENT: Individual Health Check Failure After All Retries

❌ Health Check: {result['name']}
🔗 Target: {identifier}
⚠️  Status: Failed after {result.get('attempt', 'unknown')} attempts
🕐 Timestamp: {datetime.utcnow().isoformat()}Z

Error Details:
{result.get('error', 'Unknown error')}

Additional Information:
- Retry attempts: {result.get('attempt', 'unknown')}
- Check type: {check_type.upper()}
- Configuration timeout: {config.get('timeout', 'default')}s
- Retry delay: 30s (fixed)

IMMEDIATE ACTION REQUIRED:
This health check failed completely after all retry attempts. 
The service may not be responding properly with the new database credentials.

1. Check if the service is running
2. Verify database connectivity with new credentials
3. Check service logs for connection errors
4. Validate configuration and credentials

This is an automated alert from the Secret Rotation Health Check system.
"""
        
        sns.publish(
            TopicArn=sns_topic_arn,
            Subject=subject,
            Message=message.strip()
        )
        
        logger.info(f"📤 Sent immediate failure notification for '{result['name']}' to SNS")
        
    except Exception as e:
        logger.error(f"Failed to send individual health check failure notification for '{result['name']}': {e}")

def send_failure_notification(failed_checks: List[Dict], trigger: str):
    """Send summary SNS notification for all failed health checks"""
    
    try:
        sns_topic_arn = os.environ.get('HEALTH_CHECK_SNS_TOPIC')
        if not sns_topic_arn:
            logger.warning("HEALTH_CHECK_SNS_TOPIC not configured, skipping summary notification")
            return
        
        sns = boto3.client('sns')
        
        # Prepare summary message
        subject = f"� Secret Rotation Health Check Summary - {len(failed_checks)} services failed"
        
        message_parts = [
            f"Secret Rotation Health Check Summary Report",
            f"",
            f"🔴 Failed Services: {len(failed_checks)}",
            f"🎯 Trigger: {trigger}",
            f"🕐 Timestamp: {datetime.utcnow().isoformat()}Z",
            f"",
            f"NOTE: Individual failure alerts have already been sent for each failed service.",
            f"",
            f"Failed Health Checks Summary:"
        ]
        
        for i, check in enumerate(failed_checks, 1):
            message_parts.append(f"")
            message_parts.append(f"{i}. ❌ {check['name']}")
            
            # Add appropriate identifier
            if 'function_name' in check:
                message_parts.append(f"   Lambda Function: {check['function_name']}")
            elif 'url' in check:
                message_parts.append(f"   URL: {check['url']}")
            
            message_parts.append(f"   Error: {check.get('error', 'Unknown error')}")
            
            if 'status_code' in check:
                message_parts.append(f"   Status: {check['status_code']} (expected: {check.get('expected_status', 'N/A')})")
            
            if 'attempt' in check:
                message_parts.append(f"   Failed after: {check['attempt']} attempts")
        
        message_parts.extend([
            f"",
            f"REQUIRED ACTIONS:",
            f"1. Investigate each failed service individually",
            f"2. Verify database connectivity with new credentials", 
            f"3. Check service logs for connection errors",
            f"4. Validate service configurations",
            f"",
            f"All services must be operational before considering the secret rotation complete.",
        ])
        
        message = "\n".join(message_parts)
        
        # Send summary notification
        sns.publish(
            TopicArn=sns_topic_arn,
            Subject=subject,
            Message=message
        )
        
        logger.info(f"📤 Sent summary notification to SNS topic for {len(failed_checks)} failed health checks")
        
    except Exception as e:
        logger.error(f"Failed to send summary SNS notification: {e}")

def send_lambda_failure_notification(error_message: str, event: Dict):
    """Send SNS notification for Lambda function failure"""
    
    try:
        sns_topic_arn = os.environ.get('HEALTH_CHECK_SNS_TOPIC')
        if not sns_topic_arn:
            logger.warning("HEALTH_CHECK_SNS_TOPIC not configured, skipping notification")
            return
        
        sns = boto3.client('sns')
        
        subject = "🚨 Secret Rotation Health Check Lambda Failed"
        
        message = f"""
Secret rotation health check Lambda function failed with an error.

Error: {error_message}

Event: {json.dumps(event, indent=2)}

Timestamp: {time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime())}

Please check the CloudWatch logs for more details and investigate the issue.
"""
        
        sns.publish(
            TopicArn=sns_topic_arn,
            Subject=subject,
            Message=message
        )
        
        logger.info(f"Sent Lambda failure notification to SNS topic: {sns_topic_arn}")
        
    except Exception as e:
        logger.error(f"Failed to send Lambda failure notification: {e}")