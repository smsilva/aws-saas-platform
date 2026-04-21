import os
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE'])


def handler(event, context):
    client_id = event['callerContext']['clientId']

    response = table.query(
        IndexName='client-id-index',
        KeyConditionExpression='cognito_app_client_id = :cid',
        ExpressionAttributeValues={':cid': client_id}
    )

    if not response['Items']:
        raise Exception(f"No tenant found for client_id: {client_id}")

    tenant_id = response['Items'][0]['tenant_id']

    event['response']['claimsOverrideDetails'] = {
        'claimsToAddOrOverride': {
            'custom:tenant_id': tenant_id
        }
    }
    return event
