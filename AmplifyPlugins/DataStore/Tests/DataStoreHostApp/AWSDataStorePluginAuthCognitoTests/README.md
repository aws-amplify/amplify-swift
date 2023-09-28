## DataStore with Auth Cognito Integration Tests

The following steps demonstrate how to setup a GraphQL endpoint with AppSync and Cognito User Pools.
This configuration is used to run the tests in `AWSDataStoreCategoryPluginAuthIntegrationTests.swift`.

### Set-up

1. `amplify init`

2. Make sure the correct CLI version is used for this test. 

- `amplify --v` should be at least 12.4.0
- cli.json "generatemodelsforlazyloadandcustomselectionset": true

3. `amplify add api`

```perl
? Select from one of the below mentioned services: `GraphQL`
? Here is the GraphQL API that we will create. Select a setting to edit or continue `Authorization mode`
? Choose the default authorization type for the API `Amazon Cognito User Pool`
? Configure additional auth types? `No`
? Enable conflict detection? `Yes`
? Select the default resolution strategy `Auto Merge`
? Choose a schema template: `Blank Schema`
```

Copy the content of the schema from `AWSDataStoreCategoryPluginAuthIntegrationTests/DefaultAuthCognito/singleauth-cognito-schema.graphql` into the newly created `schema.graphql` file

4. `amplify push`
```perl
? Are you sure you want to continue? `Yes`
? Do you want to generate code for your newly created GraphQL API `No`
```

5. Copy `amplifyconfiguration.json` to a new file named `AWSDataStoreCategoryPluginAuthIntegrationTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`
```
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSDataStoreCategoryPluginAuthIntegrationTests-amplifyconfiguration.json
```

6. Creating users through AWS CLI, run the following commands

```
aws cognito-idp admin-create-user --user-pool-id [POOL_ID] --username [USERNAME]
aws cognito-idp admin-set-user-password --user-pool-id [POOL_ID] --username [USERNAME] --password [PASSWORD] --permanent
```

The `[POOL_ID]` can be found in `amplifyconfiguration.json` under `auth.plugin.awsCognitoAuthPlugin.CognitoUserPool.Default.PoolId`

7. Create `AWSDataStoreCategoryPluginAuthIntegrationTests-credentials.json` inside the same folder, containing a json object of the user information from the users in the cognito user in the userpool.

```
touch ~/.aws-amplify/amplify-ios/testconfiguration/AWSDataStoreCategoryPluginAuthIntegrationTests-credentials.json
```

```json
{
    "user1": "<USERNAME>",
    "passwordUser1": "<PASSWORD>",
    "user2": "<USERNAME>",
    "passwordUser2": "<PASSWORD>"
}
```

8. Optionally, re-run `amplify codegen models` if you want to replace the existing model files under the Models directory in this project with the latest codegen output. You generally don't have to do this unless adding and testing new functionality.

Now you can run the AWSDataStoreCategoryPluginAuthIntegrationTests
