## REST API with Cognito User Pool Integration Tests

The following steps show how to set up an API endpoint with APIGateway and Lambda source. The auth configured will be Cognito User Pool. This set up is used to run the tests in `RESTWithUserPoolIntegrationTests.swift`.

### Set-up

Latest tested with amplify CLI version 8.0.1 `amplify -v`

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
Do you want to use the default authentication and security configuration? 
    Manual configuration
 Select the authentication/authorization services that you want to use: 
    User Sign-Up, Sign-In, connected with AWS IAM controls (Enables ...)
 Please provide a friendly name for your resource that will be used to label this category in the project: 
    <amplifyintegtest>
 Please enter a name for your identity pool. 
    <amplifyintegtestCIDP>
 Allow unauthenticated logins? (Provides scoped down permissions that you can control via AWS IAM) 
    No
 Do you want to enable 3rd party authentication providers in your identity pool? 
    No
 Please provide a name for your user pool: 
    <amplifyintegCUP>

 How do you want users to be able to sign in? 
    Username
 Do you want to add User Pool Groups? 
    No
 Do you want to add an admin queries API? 
    Yes
? Do you want to restrict access to the admin queries API to a specific Group 
    No
 Multifactor authentication (MFA) user login options: 
    OFF
 
 Email based user registration/forgot password: 
    Enabled (Requires per-user email entry at registration)
 Please specify an email verification subject: 
    Your verification code
 Please specify an email verification message: 
    Your verification code is {####}
 Do you want to override the default password policy for this User Pool? 
    No
 
 What attributes are required for signing up? 
   (Press Space to deselect Email, if selected, then press Enter with none selected)
 Specify the app's refresh token expiration period (in days): 
    30
 Do you want to specify the user attributes this app can read and write? 
    No
 Do you want to enable any of the following capabilities?
    (press Enter with none selected)
 Do you want to use an OAuth flow? 
    No
? Do you want to configure Lambda Triggers for Cognito? 
    Yes
? Which triggers do you want to enable for Cognito
    Pre Sign-up
    [Choose as many that you would like to manually verify later]
? What functionality do you want to use for Pre Sign-up 
    Create your own module
Succesfully added the Lambda function locally
? Do you want to edit your custom function now? Yes
Please edit the file in your editor: 
```

For Pre Sign-up lambda

```
exports.handler = (event) => {
    event.response.autoConfirmUser = true;
};
```

Continue in the terminal;

```
? Press enter to continue
Successfully added resource amplifyintegtest locally
```

4. Provision the resources. Run `amplify push` to provision the API Gateway, Lambda, and the Cognito User Pool.

5. Copy `amplifyconfiguration.json` over as `RESTWithUserPoolIntegrationTests-amplifyconfiguration.json` to `~/.aws-amplify/amplify-ios/testconfiguration/`

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

7. Retrieve your API name, you can find this in `amplifyconfiguration.json` under
```
"api": {
    "plugins": {
        "awsAPIPlugin": {
            "[API NAME]": {
```
Run `amplify console` to open the AWS Console. Navigate to API Gateway console, select your API. 

8. Add Cognito User Pool as an authorization mechanism. Select Authorizers, click on "+ Create New Authorizer", 
- type in a Name like `UserPoolAuthorizer`
- select `Cognito` as the type
- Select the Cognito UserPool, the name corresponds to the name of the user pool at the top left corner when on the User Pool console.
- For Token Source, enter `Authorization`
- Once completed, refresh the page.

9. Enable requests to the API with the Cognito User Pool Authorizer as the authorization mechanism. 
- Select Resources on the left, Under Resources, and each individual resource path, select `Any`. You will see a Test section, Method Request, Method Response, Integration Request, etc
- Click on Method Request, under Settings, Authorization, click on edit. In the drop down, select the User Pool authorizer, then click on the check mark to save it.
- Click on the OAuth Scopes and add `aws.cognito.signin.user.admin`. 
- Repeat this for each of the resource paths
- Click on Actions, deploy API, and select the deployment stage, and click Deploy.

10. Run the tests.


For more details regarding setting up a REST API with Cognito User Pools see  https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-enable-cognito-user-pool.html
