## REST API with Cognito User Pool Integration Tests

The following steps show how to set up an API endpoint with APIGateway and Lambda source. The auth configured will be Cognito User Pool. This set up is used to run the tests in `RESTWithUserPoolIntegrationTests.swift`.

### Set-up

1. Initialize an amplify project. `amplify init`

2. Create an API Gateway which proxies requests to an AWS Lambda with no authorization needed. `amplify add api`. 

```perl
? Please select from one of the below mentioned services: `REST`
? Provide a friendly name for your resource to be used as a label for this category in the project: `restAPI`
? Provide a path (e.g., /items) `/items`
? Choose a Lambda source `Create a new Lambda function`
? Provide a friendly name for your resource to be used as a label for this category in the project: `restwithuserpoolinte22de6072`
? Provide the AWS Lambda function name: `restwithuserpoolinte22de6072`
? Choose the runtime that you want to use: `NodeJS`
? Choose the function template that you want to use: `Serverless express function (Integration with Amazon API Gateway)`
? Do you want to access other resources created in this project from your Lambda function? `No`
? Do you want to invoke this function on a recurring schedule? `No`
? Do you want to configure Lambda layers for this function? `No`
? Do you want to edit the local lambda function now? `No`
Succesfully added the Lambda function locally
? Restrict API access `No`
? Do you want to add another path? `No`
Successfully added resource apid7c040db locally
```

3. Create Cognito User Pool which accepts email as the username. Run `amplify add auth`
```perl
Using service: Cognito, provided by: awscloudformation
 
 The current configured provider is Amazon Cognito. 
 
 Do you want to use the default authentication and security configuration? Default configuration
 Warning: you will not be able to edit these selections. 
 How do you want users to be able to sign in? Email
 Do you want to configure advanced settings? No, I am done.
Successfully added resource restwithuserpoolintea05fdd00 locally
```

4. Provision the resources. Run `amplify push` to provision the API Gateway, Lambda, and the Cognito User Pool.

5. Replace `RESTWithUserPoolIntegrationTests-amplifyconfiguration.json` with the generated `amplifyconfiguration.json`. 

6. In `RESTWithUserPoolIntegrationTests-amplifyconfiguration.json`. update `authorizationType` to `AMAZON_COGNITO_USER_POOLS` like so
```
{
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "api": {
        "plugins": {
            "awsAPIPlugin": {
                "apid7c040db": {
                    "endpointType": "REST",
                    "endpoint": "https://endpoint.execute-api.us-west-2.amazonaws.com/devo",
                    "region": "us-west-2",
                    "authorizationType": "AMAZON_COGNITO_USER_POOLS"
                }
            }
        }
    }
}

```

7. Create a new user in the userpool. First, retrieve the Cognito User Pool's Pool Id, you can find this in `amplifyconfiguration.json` under
```
"CognitoUserPool": {
    "Default": {
        "PoolId": "[POOL_ID]",
```
Run the `admin-create-user` command to create a new user
```
aws cognito-idp admin-create-user --user-pool-id [POOL_ID] --username [USER EMAIL]
```
Run the `admin-set-user-password` command to confirm the user
```
aws cognito-idp admin-set-user-password --user-pool-id [POOL_ID] --username [USER EMAIL] --password [PASSWORD] --permanent
```
See https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/index.html#cli-aws-cognito-idp for more details using AWS CLI

8. Update `RESTWithUserPoolIntegrationTests-credentials.json` with a json object containing `user1` and `password` with the crendentials of the user that was created in the previous step 

```json
{
    "user1": "[USER EMAIL]",
    "password": "[PASSWORD]"
}

```

9. Retrieve your API name, you can find this in `amplifyconfiguration.json` under
```
"api": {
    "plugins": {
        "awsAPIPlugin": {
            "[API NAME]": {
```
Run `amplify console` to open the AWS Console. Navigate to API Gateway console, select your API. 

10. Add Cognito User Pool as an authorization mechanism. Select Authorizers, click on "+ Create New Authorizer", 
- type in a Name like `UserPoolAuthorizer`
- select `Cognito` as the type
- Select the Cognito UserPool, the name corresponds to the name of the user pool at the top left corner when on the User Pool console.
- For Token Source, enter `Authorization`
- Once completed, refresh the page.

11. Enable requests to the API with the Cognito User Pool Authorizer as the authorization mechanism. 
- Select Resources on the left, Under Resources, and each individual resource path, select `Any`. You will see a Test section, Method Request, Method Response, Integration Request, etc
- Click on Method Request, under Settings, Authorization, click on edit. In the drop down, select the User Pool authorizer, then click on the check mark to save it.
- Click on the OAuth Scopes and add `aws.cognito.signin.user.admin`. 
- Repeat this for each of the resource paths
- Click on Actions, deploy API, and select the deployment stage, and click Deploy.

12. Run the tests.


For more details regarding setting up a REST API with Cognito User Pools see  https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-enable-cognito-user-pool.html
