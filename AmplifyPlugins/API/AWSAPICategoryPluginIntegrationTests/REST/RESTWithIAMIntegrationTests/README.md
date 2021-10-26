## REST API with IAM Auth Integration Tests

The following steps show how to set up an API endpoint with APIGateway and Lambda source. The auth configured will be IAM. This set up is used to run the tests in `RESTWithIAMIntegrationTests.swift`.

### Set-up

1. `amplify init`

2. `amplify add api`.  Below follows these steps closely: https://aws-amplify.github.io/docs/ios/api#rest-api
```perl
? Please select from one of the below mentioned services: `REST`
? Provide a friendly name for your resource to be used as a label for this category in the project: `restAPI`
? Provide a path (e.g., /items) `/items`
? Choose a Lambda source `Create a new Lambda function`
? Provide a friendly name for your resource to be used as a label for this category in the project: `restwithiamintegratie962cff0`
? Provide the AWS Lambda function name: `restwithiamintegratie962cff0`
? Choose the runtime that you want to use: NodeJS
? Choose the function template that you want to use: `Serverless ExpressJS function (Integration with API Gateway)`
? Do you want to configure advanced settings? `Yes`
? Do you want to access other resources created in this project from your Lambda function? `No`
? Do you want to invoke this function on a recurring schedule? `No`
? Do you want to configure Lambda layers for this function? `No`
? Do you want to edit the local lambda function now? `No`
Succesfully added the Lambda function locally
? Restrict API access `Yes`
? Who should have access? `Authenticated and Guest users`
? What kind of access do you want for Authenticated users? `create, read, update, delete`
? What kind of access do you want for Guest users? `create, read, update, delete`
Successfully added auth resource locally.
? Do you want to add another path? `No`
Successfully added resource api1ed65adc locally
```
3. Create a file `RESTWithIAMIntegrationTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/` and copy `amplifyconfiguration.json` 

4. Run the tests
