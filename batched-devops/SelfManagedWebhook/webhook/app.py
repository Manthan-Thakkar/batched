import json
import os
import boto3

# Initialize the SNS client and get the SNS Topic ARN from environment variables
sns_client = boto3.client('sns')

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))
    
    # Parse the webhook event body
    try:
        payload = json.loads(event.get('body', '{}'))
    except json.JSONDecodeError:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Invalid JSON payload"})
        }
    
    # Extract information from the payload
    monitor = payload.get('Title', {})
    alert_msg = payload.get('Body', 'No additional message provided')
    alert_type = payload.get('AlertType', {})
    print(alert_type.upper())
    
    # Map alert types to corresponding topic ARNs
    topic_map = {
        'DEFAULT': os.environ.get('SNS_TOPIC_ARN'),
        'IMPORTANT': os.environ.get('IMPORTANT_SNS_TOPIC_ARN'),
        'LABELTRAXX': os.environ.get('LABELTRAXX_SNS_TOPIC_ARN')
    }

    # Construct the SNS message payload
    message = (
        f"Alert Details: {alert_msg}"
    )
    
    subject = f"Alert from {monitor}"
    # Publish the message to the SNS topic
    try:
        response = sns_client.publish(
            TopicArn=topic_map.get(alert_type.upper(), 'DEFAULT'),
            Message=message,
            Subject=subject
        )
        print("SNS publish response:", response)
    except Exception as e:
        print("Error publishing to SNS:", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Failed to publish message"})
        }
    
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Notification sent successfully", "sns_response": response})
    }
