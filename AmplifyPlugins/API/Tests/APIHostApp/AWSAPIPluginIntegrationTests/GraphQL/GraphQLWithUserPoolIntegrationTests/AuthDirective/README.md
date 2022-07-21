## GraphQL with UserPool Auth Integration Tests

The following steps demonstrate how to set up an GraphQL endpoint with AppSync. The auth configured will be Cognito UserPools. This set up is used to run the tests in `GraphQLAuthDirectiveIntegrationTests.swift`.

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
? What best describes your project: `Single object with fields (e.g., “Todo” with ID, name, description)`
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

5. Copy `amplifyconfiguration.json` over as `GraphQLAuthDirectiveIntegrationTests-amplifyconfiguration.json` to `~/.aws-amplify/amplify-ios/testconfiguration/`
6. Create `GraphQLAuthDirectiveIntegrationTests-credentials.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/` with a json object containing `user1`, and `password`, used to create the cognito user in the userpool. In step 2, the cognito userpool is configured to allow users to sign up with their email as the username.

```json
{
    "user1": "[USER EMAIL]",
    "passwordUser1": "[PASSWORD]"
    "user2": "[USER2 EMAIL]",
    "passwordUser2": "[PASSWORD]"
}

```

7. Create a two new users in the userpool. First, retrieve the Cognito User Pool's Pool Id, you can find this in `amplifyconfiguration.json` under
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

You can now run the tests!
