## GraphQL with Lambda Auth Integration Tests

The following steps demonstrate how to set up an GraphQL endpoint with AppSync. The auth configured will be IAM. This set up is used to run the tests in `GraphQLWithLambdaAuthIntegrationTests.swift`.

### Set-up

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

3. `amplify push`

4. Copy `amplifyconfiguration.json` over as `GraphQLWithLambdaAuthIntegrationTests-amplifyconfiguration.json`
5. Copy `awsconfiguration.json` over as `GraphQLWithLambdaAuthIntegrationTests-awsconfiguration.json`
6. Replace the authorization type `API_KEY` with  `AWS_LAMBDA` in `GraphQLWithLambdaAuthIntegrationTests-amplifyconfiguration.json` and  `GraphQLWithLambdaAuthIntegrationTests-awsconfiguration.json`

7. `amplify console` and choose Lambda.
8. create a new Lambda function called "AuthorizerLambda" as the following
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
9. still in the AWSConsole, go to AppSync, select your app, set the authorization type as "Lambda" and select the newly created Lambda function



Note: steps 4..7 and 9 should be updated when the CLI supports this new authorization type.

You can now run the tests!
