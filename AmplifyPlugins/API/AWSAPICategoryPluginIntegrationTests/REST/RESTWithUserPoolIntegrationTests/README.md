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
? Choose the function template that you want to use: `Serverless express function (Integration with Amazon API Gateway)`
? Do you want to access other resources created in this project from your Lambda function? `No`
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

5. Replace `RESTWithUserPoolIntegrationTests-amplifyconfiguration.json` and `RESTWithPoolIntegrationTests-awsconfiguration.json` with the generated `amplifyconfiguration.json` and `awsconfiguration.json` . 

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

7. Create a new user in the userpool. One method is to sign up the using `AWSMobileClient` and then open the User Pools console using `amplify console auth`. Select Users and groups, select the user, and click Confirm.

8. Update `RESTWithUserPoolIntegrationTests-credentials.json` with a json object containing `user1` and `password` with the crendentials of the user that was created in the previous step 

```json
{
    "user1": "<USER EMAIL>",
    "password": "<PASSWORD>"
}

```

9. Find your API name. Run `amplify console` to open the AWS Console. The latest deployment activty logs will indicate the API Gateway that is provisioned. There will be a Resource ID that looks like `<api name> (api)`. Navigate to API Gateway console, select your API. 

10. Find your Cognito User Pool name by click on the Authentication tab in the AWS Console.

10. Add Cognito User Pool as an authorization mechanism. Select Authorizers, click on "+ Create New Authorizer", 
- type in a Name
- select `Cognito` as the type
- Select the Cognito UserPool
- For Token Source, enter `Authorization`
- Once completed, refresh the page.

11. Enable requests to the API with the Cognito User Pool Authorizer as the authorization mechanism. 
- Select Resources on the left, Under Resources, and each individual resource path, select `Any`. You will see a Test section, Method Request, Method Response, Integration Request, etc
- Click on Method Request, under Settings, Authorization, click on edit. In the drop down, select the User Pool authorizer, then click on the check mark to save it.
- Repeat this for each of the resource paths
- Click on Actions, deploy API, and select the deployment stage, and click Deploy.

12. Run the tests.
