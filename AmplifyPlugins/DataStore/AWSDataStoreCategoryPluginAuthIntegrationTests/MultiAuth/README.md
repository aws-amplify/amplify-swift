## DataStore with Multi-Auth Integration Tests

### Prerequisites
- AWS CLI

### Set-up

1. create a `schema.graphql` file with the content of  `MultiAuth/schema.graphql`

2. `amplify init`

3. `amplify add api` (when asked, provide **"datastoreintegtestmu"** as API name)
```
? Please select from one of the below mentioned services: `GraphQL`
? Provide API name: `datastoreintegtestmu`
? Choose the default authorization type for the API: `API key`
? Enter a description for the API key:
? After how many days from now the API key should expire (1-365): `365`
? Do you want to configure advanced settings for the GraphQL API `Yes, I want to make some additional changes.`
? Configure additional auth types? `Yes`
? Choose the additional authorization types you want to configure for the API: `Amazon Cognito User Pool`, `IAM`
? Enable conflict detection? `Yes`
? Select the default resolution strategy Auto Merge
? Do you have an annotated GraphQL schema? `Yes`
? Provide your schema file path: `schema.graphql`
```
4. `amplify push`
```perl
? Are you sure you want to continue? `Yes`
? Do you want to generate code for your newly created GraphQL API `No`
```

5. Copy `amplifyconfiguration.json` to a new file named `AWSDataStoreCategoryPluginMultiAuthIntegrationTests-amplifyconfiguration.json`
6. Create `AWSDataStoreCategoryPluginMultiAuthIntegrationTests-credentials.json` with the following value
```json
{
    "user1": "<USER1_EMAIL>",
    "passwordUser1": "<PASSWORD_1>",
    "user2": "<USER2_EMAIL>",
    "passwordUser2": "<PASSWORD_2>"
}

```
7. Replace `USER1_EMAIL`, `PASSWORD_1`, `USER2_EMAIL`,  `PASSWORD_2`  with values for test users
8. Run the following commands to create the above users and set their passwords

`aws cognito-idp admin-create-user --user-pool-id <USER_POOL_ID> --username USER1_EMAIL`
`aws cognito-idp admin-set-user-password --user-pool-id <USER_POOL_ID>  --username USER1_EMAIL --password PASSWORD_1 --permanent`

`aws cognito-idp admin-create-user --user-pool-id <USER_POOL_ID> --username USER2_EMAIL`
`aws cognito-idp admin-set-user-password --user-pool-id <USER_POOL_ID>  --username USER2_EMAIL --password PASSWORD_2 --permanent`

9. Create a `Admins` group in the `<USER_POOL_ID>` user pool
10. Add `user1` to `Admins` group 
11. Some test cases require IAM to allow guest access. To do so run `amplify update auth` and follow the instructions
```
What do you want to do? `Walkthrough all the auth configurations`
Select the authentication/authorization services that you want to use: `User Sign-Up, Sign-In, connected with AWS IAM controls (Enables per-user Storage features for images or other content, Analytics, a
nd more)`
Allow unauthenticated logins? (Provides scoped down permissions that you can control via AWS IAM) `Yes`
Do you want to enable 3rd party authentication providers in your identity pool? `No`
Do you want to add User Pool Groups? `No`
Do you want to add an admin queries API? `No`
Multifactor authentication (MFA) user login options: `OFF`
Email based user registration/forgot password: `Enabled (Requires per-user email entry at registration)`
Please specify an email verification subject: `Your verification code`
Please specify an email verification message: `Your verification code is {####}`
Do you want to override the default password policy for this User Pool? `No`
Specify the app's refresh token expiration period (in days): `30`
Do you want to specify the user attributes this app can read and write? `No`
Do you want to enable any of the following capabilities? 
Do you want to use an OAuth flow? `No`
? Do you want to configure Lambda Triggers for Cognito? `No`
```
Then `amplify push`

