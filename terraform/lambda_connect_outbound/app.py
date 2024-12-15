import json
import boto3
import os
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

connect_client = boto3.client('connect')


def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event))

    try:
        phone_number = event.get("queryStringParameters", {}).get("phone_number", "").strip()
        api_path = event.get("path", "").strip("/")

        logger.info("Extracted phone number: '%s'", phone_number)
        logger.info("Extracted API path: '%s'", api_path)

        if not phone_number:
            logger.error("Phone number is missing from the request")
            raise ValueError("Phone number is required")

        if not phone_number.startswith("+"):
            phone_number = f"+{phone_number}"
            logger.info("Formatted phone number to: '%s'", phone_number)

        api_messages = {
            "boss": "There is an emergency! Call your supervisor immediately!",
            "mom": "Hey honey! I need you to call me right away!",
            "police": "This is an emergency. Please contact the police immediately!",
            "sister": "Hey, it's your crazy sister! You'll never guess what happened! Call me right away!",
        }

        logger.info("Available API message paths: %s", list(api_messages.keys()))

        message_text = api_messages.get(api_path, "There is an emergency. Please respond immediately.")
        logger.info("Message selected for path '%s': '%s'", api_path, message_text)

        instance_id = os.environ.get('CONNECT_INSTANCE_ID')
        flow_id = os.environ.get('CONNECT_FLOW_ID')
        source_phone_number = os.environ.get('CONNECT_PHONE_NUMBER')
        logger.info("Using Connect Instance ID: '%s'", instance_id)
        logger.info("Using Connect Flow ID: '%s'", flow_id)
        logger.info("Using Source Phone Number: '%s'", source_phone_number)

        if not instance_id or not flow_id or not source_phone_number:
            logger.error("One or more required environment variables are missing")
            raise ValueError("Missing environment variables for Connect configuration")

        response = connect_client.start_outbound_voice_contact(
            InstanceId=instance_id,
            ContactFlowId=flow_id,
            DestinationPhoneNumber=phone_number,
            SourcePhoneNumber=source_phone_number,
            Attributes={
                "emergency_message": message_text
            }
        )

        logger.info("Connect API response: %s", json.dumps(response))

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Call initiated successfully",
                "contact_id": response['ContactId']
            })
        }
    except Exception as e:
        logger.exception("An error occurred during Lambda execution")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
