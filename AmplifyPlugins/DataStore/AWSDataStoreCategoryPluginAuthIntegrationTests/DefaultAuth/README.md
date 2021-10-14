## DataStore with Auth Integration Tests

The following steps demonstrate how to setup a GraphQL endpoint with AppSync and Cognito User Pools.
This configuration is used to run the tests in `AWSDataStoreCategoryPluginAuthIntegrationTests.swift`.

### Set-up

1. `amplify init`

2. `amplify add api`

```perl
? Please select from one of the below mentioned services: GraphQL
? Provide API name: `<APIName>`
? Choose the default authorization type for the API `Amazon Cognito User Pool`
? Do you want to use the default authentication and security configuration? `Default configuration`
? How do you want users to be able to sign in? `Email`
? Do you want to configure advanced settings? `No, I am done.`
? Do you want to configure advanced settings for the GraphQL API `No, I am done.`
? Do you have an annotated GraphQL schema? `No`
? Do you want a guided schema creation? `Yes`
? Do you want to edit the schema now? `No`
```

The guided schema provided should look like this: 
```json
type SocialNote
    @model
    @auth(rules: [
        { allow: owner, ownerField: "owner", operations: [create, update, delete] },
    ]) {
    id: ID!
    content: String!
    owner: String
}
```

3. `amplify update api`
? Please select from one of the below mentioned services: `GraphQL`
? Select from the options below `Enable DataStore for entire API`

4. `amplify push`
```perl
? Are you sure you want to continue? `Yes`
? Do you want to generate code for your newly created GraphQL API `No`
```

5. Copy `amplifyconfiguration.json` to a new file named `AWSDataStoreCategoryPluginAuthIntegrationTests-amplifyconfiguration.json`
6. Create `AWSDataStoreCategoryPluginAuthIntegrationTests-credentials.json` with a json object containing `user1`, and `password`, used to create the cognito user in the userpool. In step 2, the cognito userpool is configured to allow users to sign up with their email as the username.

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

The `[POOL_ID]` can be found in `amplifyconfiguration.json` under `auth.plugsin.awsCognitoAuthPlugin.CognitoUserPool.Default.PoolId`

Now you can run the AWSDataStoreCategoryPluginAuthIntegrationTests
