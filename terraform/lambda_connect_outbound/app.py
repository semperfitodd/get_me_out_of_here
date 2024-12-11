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

        if not phone_number:
            raise ValueError("Phone number is required")

        if not phone_number.startswith("+"):
            phone_number = f"+{phone_number}"

        response = connect_client.start_outbound_voice_contact(
            InstanceId=os.environ['CONNECT_INSTANCE_ID'],
            ContactFlowId=os.environ['CONNECT_FLOW_ID'],
            DestinationPhoneNumber=phone_number,
            SourcePhoneNumber=os.environ['CONNECT_PHONE_NUMBER']
        )

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Call initiated successfully",
                "contact_id": response['ContactId']
            })
        }
    except Exception as e:
        logger.exception("An error occurred")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
