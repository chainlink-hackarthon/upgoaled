import os
import json
import boto3
import requests
from chainlink import Chainlink

def lambda_handler(event, context):
    # Step 1: Get Strava OAuth credentials
    client_id = os.environ['STRAVA_CLIENT_ID']
    client_secret = os.environ['STRAVA_CLIENT_SECRET']

    # Step 2: Set up Chainlink variables
    chainlink_api_key = os.environ['CHAINLINK_API_KEY']
    chainlink_secret = os.environ['CHAINLINK_SECRET']
    chainlink_url = os.environ['CHAINLINK_URL']
    
    # Step 3: Implement OAuth flow with Strava
    code = event['queryStringParameters']['code']
    strava_token_url = 'https://www.strava.com/oauth/token'
    payload = {
        'client_id': client_id,
        'client_secret': client_secret,
        'code': code,
        'grant_type': 'authorization_code'
    }
    
    response = requests.post(strava_token_url, data=payload)
    response_json = response.json()
    
    if 'access_token' not in response_json:
        return {
            'statusCode': 400,
            'body': json.dumps('OAuth process failed')
        }

    access_token = response_json['access_token']
    
    # Step 4: Create Chainlink request and callback
    chainlink_client = Chainlink(chainlink_api_key, chainlink_secret, chainlink_url)
    data = {
        'access_token': access_token,
        'external_adapter_name': 'strava_oauth_callback'
    }
    chainlink_response = chainlink_client.create_request(data)
    
    if not chainlink_response:
        return {
            'statusCode': 500,
            'body': json.dumps('Failed to create Chainlink request')
        }

    # Step 5: Return a successful response
    return {
        'statusCode': 200,
        'body': json.dumps('OAuth and Chainlink process succeeded')
    }