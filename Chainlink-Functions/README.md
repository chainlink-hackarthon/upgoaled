# chainlink_functions: Lambda Function for Chainlink OAuth with Strava
This AWS Lambda function implements an OAuth flow with Strava and then creates a Chainlink request to use the obtained Strava access token.

Installation
This Lambda function requires the following environment variables to be set:
```sh
STRAVA_CLIENT_ID: the client ID for your Strava application
STRAVA_CLIENT_SECRET: the client secret for your Strava application
CHAINLINK_API_KEY: the API key for your Chainlink node
CHAINLINK_SECRET: the secret for your Chainlink node
CHAINLINK_URL: the URL for your Chainlink node
You also need to have the chainlink library installed. You can install it via pip:
```
```sh
pip install chainlink
```
# Usage
To use this Lambda function, you need to create an endpoint that triggers it. The endpoint should expect a GET request with a code query parameter, which is the authorization code obtained from Strava.

When the Lambda function is triggered, it will perform the following steps:

Get Strava OAuth credentials from the environment variables
Set up Chainlink variables from the environment variables
Implement OAuth flow with Strava and obtain an access token
Create a Chainlink request using the obtained access token and a callback
Return a successful response if the process succeeded
If any step fails, the Lambda function will return an error response with a corresponding status code and message.

Example
Here is an example of how you can use this Lambda function in a serverless application with API Gateway:

```yaml
# serverless.yml

service: my-service

provider:
  name: aws
  runtime: python3.8

functions:
  chainlink-oauth:
    handler: lambda_function.lambda_handler
    environment:
      STRAVA_CLIENT_ID: 'your-strava-client-id'
      STRAVA_CLIENT_SECRET: 'your-strava-client-secret'
      CHAINLINK_API_KEY: 'your-chainlink-api-key'
      CHAINLINK_SECRET: 'your-chainlink-secret'
      CHAINLINK_URL: 'https://your-chainlink-node-url.com'
    events:
      - http:
          path: chainlink-oauth
          method: get
          cors: true
          ```
In this example, the Lambda function is named chainlink-oauth and is triggered by a GET request to the /chainlink-oauth endpoint.

To trigger the Lambda function from your client application, you can redirect the user to the endpoint with the code query parameter set to the authorization code obtained from Strava:


``https://your-api-gateway-url.com/chainlink-oauth?code=your-strava-authorization-code``
When the Lambda function completes successfully, it will return a response with a 200 status code and a message indicating that the OAuth and Chainlink process succeeded.
