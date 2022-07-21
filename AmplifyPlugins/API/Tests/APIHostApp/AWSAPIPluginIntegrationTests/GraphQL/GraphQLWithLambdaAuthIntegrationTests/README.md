## GraphQL with Lambda Auth Integration Tests

The following steps demonstrate how to set up an GraphQL endpoint with AppSync. The auth configured will be IAM. This set up is used to run the tests in `GraphQLWithLambdaAuthIntegrationTests.swift`.

### Set-up

Latest tested with amplify CLI version 8.0.1 `amplify -v`

1. `amplify init`

2. `amplify add api`

```perl
? Please select from one of the below mentioned services: `GraphQL`
? Provide API name: graphqlmodelapitests
? Choose the default authorization type for the API `API KEY`
? Do you want to configure advanced settings for the GraphQL API `No, I am done.`
? Do you have an annotated GraphQL schema? `No`
? Choose a schema template: `Single object with fields (e.g., “Todo” with ID, name, description)`
```

3. If you are using the latest CLI, update cli.json to include `"useExperimentalPipelinedTransformer": false` to ensure that it will use the v1 transformer and then `amplify push`

4. Copy `amplifyconfiguration.json` over as `GraphQLWithLambdaAuthIntegrationTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/` 
5. Replace the authorization type `API_KEY` with  `AWS_LAMBDA` in `GraphQLWithLambdaAuthIntegrationTests-amplifyconfiguration.json` 

6. Run `amplify console` to open the AWS Console
7. Select `AWS Lambda` and create a new Lambda function called "AuthorizerLambda" with the following content
```
exports.handler = async (event) => {
    console.log(`auth event >`, JSON.stringify(event, null, 2))
    const {
        authorizationToken,
        requestContext: { apiId, accountId },
      } = event
    const response = {
      isAuthorized: authorizationToken === 'custom-lambda-token',
      ttlOverride: 10,
    }
    console.log(`response >`, JSON.stringify(response, null, 2))
    return response
};
```
8. still in the AWSConsole, navigate to `AWS AppSync` and select the app you've created before
9. In the "Settings" panel under "Default authorization mode", set the authorization type as `AWS Lambda` and select the newly created Lambda function

Note: steps 4..9 should be updated when the CLI supports this new authorization type.

You can now run the tests!
