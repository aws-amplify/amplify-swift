## GraphQL with IAM Auth Integration Tests

The following steps demonstrate how to set up an GraphQL endpoint with AppSync. The auth configured will be IAM. This set up is used to run the tests in `GraphQLWithIAMIntegrationTests.swift`.

### Set-up

1. `amplify init`

2. `amplify add api`

```perl
? Please select from one of the below mentioned services: `GraphQL`
? Provide API name: graphqlmodelapitests
? Choose the default authorization type for the API `IAM`
? Do you want to configure advanced settings for the GraphQL API `No, I am done.`
? Do you have an annotated GraphQL schema? `No`
? Choose a schema template: `Single object with fields (e.g., “Todo” with ID, name, description)`
```
Edit the schema to
```
type Todo @model @auth(rules: [
  { allow: public, provider: iam }, 
  { allow: private, provider: iam }]) {
  id: ID!
  name: String!
  description: String
}

```

3. `amplify add auth`
```perl
? Do you want to use the default authentication and security configuration? `Default configuration`
? How do you want users to be able to sign in? `Username`
? Do you want to configure advanced settings? `No, I am done.`
```

4. `amplify push`

5. Copy `amplifyconfiguration.json` over as `GraphQLWithIAMIntegrationTests-amplifyconfiguration.json` to `~/.aws-amplify/amplify-ios/testconfiguration/`

6. `amplify console auth` and choose `Identity Pool`. Click on **Edit Identity pool** and make note of IAM Role that is assigned for the Authenticated role.

7. Click on `Unauthenticated identities` and check off *Enable access to unauthenticated identities*, and Save Changes. This will allow users that are using the app but are not signed in to assume the unauthenticated role when making calls to the API.

8. Navigate to [AWS IAM Console](https://console.aws.amazon.com/iam/home) and select Roles, find the role attached to the Identity Pool's Authenticated role.

9. Click on Attach Policies, choose **AWSAppSyncInvokeFullAccess**, and attach the policy. This will allow users that are signed into the app to have access to invoke AppSync APIs.

10. Create `GraphQLWithIAMIntegrationTests-credentials.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/` with a json object containing `username`, and `password`, used to create the cognito user in the userpool. 

```json
{
    "username": "[USERNAME]",
    "password": "[PASSWORD]"
}
```

11. Create a new users in the userpool. First, retrieve the Cognito User Pool's Pool Id, you can find this in `amplifyconfiguration.json` under
```
"CognitoUserPool": {
    "Default": {
        "PoolId": "[POOL_ID]",
```
Run the `admin-create-user` command to create a new user
```
aws cognito-idp admin-create-user --user-pool-id [POOL_ID] --username [USERNAME]
```
Run the `admin-set-user-password` command to confirm the user
```
aws cognito-idp admin-set-user-password --user-pool-id [POOL_ID] --username [USERNAME] --password [PASSWORD] --permanent
```
See https://docs.aws.amazon.com/cli/latest/reference/cognito-idp/index.html#cli-aws-cognito-idp for more details using AWS CLI. 

You can now run the tests!
