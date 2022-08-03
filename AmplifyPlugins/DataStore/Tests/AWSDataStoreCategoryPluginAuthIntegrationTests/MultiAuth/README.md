## DataStore with Multi-Auth Integration Tests

### Prerequisites
- AWS CLI
- Version used: `amplify -v` => `8.0.1`

### Set-up

1. `amplify init`

These tests were provisioned with V1 Transform:

- cli.json "transformerversion": 1
- cli.json "useexperimentalpipelinedtransformer": false

TODO: Update the schema and tests to use V2 Transform.

2. `amplify add api`

```
? Select from one of the below mentioned services: `GraphQL`
? Provide API name: <provide any name>
? Choose the default authorization type for the API: `API key`
? Enter a description for the API key:
? After how many days from now the API key should expire (1-365): `365`

? Configure additional auth types? `Yes`
? Choose the additional authorization types you want to configure for the API: `Amazon Cognito User Pool`, `IAM`
?  Do you want to use the default authentication and security configuration? `Manual configuration`
? Select the authentication/authorization services that you want to use: `User Sign-Up, Sign-In, connected with AWS IAM controls (Enables per-user Storage features for images or ot
her content, Analytics, and more)`
? Provide a friendly name for your resource that will be used to label this category in the project: <provide name>
? Enter a name for your identity pool. <provide name>
? Allow unauthenticated logins? (Provides scoped down permissions that you can control via AWS IAM) `Yes`
? Do you want to enable 3rd party authentication providers in your identity pool? `No`
? Provide a name for your user pool: <provide name>
 
? How do you want users to be able to sign in? `Username`
? Do you want to add User Pool Groups? `No`
? Do you want to add an admin queries API? `No`
? Multifactor authentication (MFA) user login options: `OFF`
? Email based user registration/forgot password: `Enabled (Requires per-user email entry at registration)`
? Specify an email verification subject: `Your verification code`
? Specify an email verification message: `Your verification code is {####}`
? Do you want to override the default password policy for this User Pool? `No`
 
? What attributes are required for signing up? `Email`
? Specify the app's refresh token expiration period (in days): `30`
? Do you want to specify the user attributes this app can read and write? `No`
? Do you want to enable any of the following capabilities? None
? Do you want to use an OAuth flow? `No`
? Do you want to configure Lambda Triggers for Cognito? `No`



? Enable conflict detection? `Yes`
? Select the default resolution strategy Auto Merge
? Choose a schema template: Blank Schema
? Do you want to edit the schema now? (Y/n) 'Y'

Copy the contents from `MultiAuth/schema.graphql`

```

3. `amplify push`

```perl
? Are you sure you want to continue? `Yes`
? Do you want to generate code for your newly created GraphQL API `No`
```

4. Copy `amplifyconfiguration.json` to a new file named `AWSDataStoreCategoryPluginMultiAuthIntegrationTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`

```perl
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSDataStoreCategoryPluginMultiAuthIntegrationTests-amplifyconfiguration.json
```

5. Create `AWSDataStoreCategoryPluginMultiAuthIntegrationTests-credentials.json` inside the same folder with the following value

```json
{
    "user1": "<USER1_EMAIL>",
    "passwordUser1": "<PASSWORD_1>",
    "user2": "<USER2_EMAIL>",
    "passwordUser2": "<PASSWORD_2>"
}

```
6. Replace `USER1_EMAIL`, `PASSWORD_1`, `USER2_EMAIL`,  `PASSWORD_2`  with values for test users

7. Run the following commands to create the above users and set their passwords

`aws cognito-idp admin-create-user --user-pool-id <USER_POOL_ID> --username USER1_EMAIL`
`aws cognito-idp admin-set-user-password --user-pool-id <USER_POOL_ID>  --username USER1_EMAIL --password PASSWORD_1 --permanent`

`aws cognito-idp admin-create-user --user-pool-id <USER_POOL_ID> --username USER2_EMAIL`
`aws cognito-idp admin-set-user-password --user-pool-id <USER_POOL_ID>  --username USER2_EMAIL --password PASSWORD_2 --permanent`

8. Create a `Admins` group in the `<USER_POOL_ID>` user pool

9. Add `user1` to `Admins` group 
