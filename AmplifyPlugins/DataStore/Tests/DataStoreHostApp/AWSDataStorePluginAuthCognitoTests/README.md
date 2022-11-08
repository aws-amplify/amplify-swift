## DataStore with Auth Cognito Integration Tests

The following steps demonstrate how to setup a GraphQL endpoint with AppSync and Cognito User Pools.
This configuration is used to run the tests in `AWSDataStoreCategoryPluginAuthIntegrationTests.swift`.

### Set-up

1. `amplify init`

2. Make sure the correct CLI version is used for this test. 

- `amplify --v` should be at least 8.5.2
- cli.json "transformerversion": 2
- cli.json "useexperimentalpipelinedtransformer": true
- cli.json "usesubusernamefordefaultidentityclaim": true

3. `amplify add api`

```perl
? Select from one of the below mentioned services: GraphQL
  Authorization modes: Amazon Cognito User Pool (default) 
  Conflict detection (required for DataStore): Enabled 
  Conflict resolution strategy: Auto Merge
? Choose a schema template: Blank Schema  
? Do you want to edit the schema now? `Yes`
```

Copy the content of the schema from `AWSDataStoreCategoryPluginAuthIntegrationTests/DefaultAuthCognito/singleauth-cognito-schema.graphql` into the newly created `schema.graphql` file

3. `amplify update api`
? Please select from one of the below mentioned services: `GraphQL`
? Select from the options below `Enable DataStore for entire API`

4. `amplify push`
```perl
? Are you sure you want to continue? `Yes`
? Do you want to generate code for your newly created GraphQL API `No`
```

5. Copy `amplifyconfiguration.json` to a new file named `AWSDataStoreCategoryPluginAuthIntegrationTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`
```
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSDataStoreCategoryPluginAuthIntegrationTests-amplifyconfiguration.json
```

6. Create `AWSDataStoreCategoryPluginAuthIntegrationTests-credentials.json` inside the same folder with a json object containing `user1`, and `password`, used to create the cognito user in the userpool. In step 2, the cognito userpool is configured to allow users to sign up with their email as the username.

```json
{
    "user1": "<USER EMAIL>",
    "passwordUser1": "<PASSWORD>",
    "user2": "<USER2 EMAIL>",
    "passwordUser2": "<PASSWORD>"
}

```

### Creating users through AWS Console

7. `amplify console auth`
```perl
? Which console `User Pool`
```

8. Click on `Users and groups`, Sign up the two new users with the email and a temporary password. 

9. Click on App clients, and keep note of the app client web's `App client id`. This can be used the AWS AppSync console Queries.

10. `amplify console api`
Click on Queries tab, and click on Log in. This will prompt you to enter the app client id, username, and temporary password. After logging in successfully, it will ask you to enter a new password. Make sure those are the same as the one specified in the credentials json file from step 5. Do this for both users.


### Creating users through AWS CLI

7. Run the following commands

```
aws cognito-idp admin-create-user --user-pool-id [POOL_ID] --username [USER EMAIL]
aws cognito-idp admin-set-user-password --user-pool-id [POOL_ID] --username [USER EMAIL] --password [PASSWORD] --permanent
```

The `[POOL_ID]` can be found in `amplifyconfiguration.json` under `auth.plugin.awsCognitoAuthPlugin.CognitoUserPool.Default.PoolId`

Now you can run the AWSDataStoreCategoryPluginAuthIntegrationTests
