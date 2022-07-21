## GraphQL with IAM Auth Integration Tests

The following steps demonstrate how to set up an GraphQL endpoint with AppSync. The auth configured will be IAM. This set up is used to run the tests in `GraphQLWithIAMIntegrationTests.swift`.

### Set-up

Latest tested with amplify CLI version 8.0.1 `amplify -v`

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
Do you want to use the default authentication and security configuration? 
    Manual configuration
 Select the authentication/authorization services that you want to use: 
    User Sign-Up, Sign-In, connected with AWS IAM controls (Enables ...)
 Please provide a friendly name for your resource that will be used to label this category in the project: 
    <amplifyintegtest>
 Please enter a name for your identity pool. 
    <amplifyintegtestCIDP>
 Allow unauthenticated logins? (Provides scoped down permissions that you can control via AWS IAM) 
    Yes
 Do you want to enable 3rd party authentication providers in your identity pool? 
    No
 Please provide a name for your user pool: 
    <amplifyintegCUP>

 How do you want users to be able to sign in? 
    Username
 Do you want to add User Pool Groups? 
    No
 Do you want to add an admin queries API? 
    Yes
? Do you want to restrict access to the admin queries API to a specific Group 
    No
 Multifactor authentication (MFA) user login options: 
    OFF
 
 Email based user registration/forgot password: 
    Enabled (Requires per-user email entry at registration)
 Please specify an email verification subject: 
    Your verification code
 Please specify an email verification message: 
    Your verification code is {####}
 Do you want to override the default password policy for this User Pool? 
    No
 
 What attributes are required for signing up? 
   (Press Space to deselect Email, if selected, then press Enter with none selected)
 Specify the app's refresh token expiration period (in days): 
    30
 Do you want to specify the user attributes this app can read and write? 
    No
 Do you want to enable any of the following capabilities?
    (press Enter with none selected)
 Do you want to use an OAuth flow? 
    No
? Do you want to configure Lambda Triggers for Cognito? 
    Yes
? Which triggers do you want to enable for Cognito
    Pre Sign-up
    [Choose as many that you would like to manually verify later]
? What functionality do you want to use for Pre Sign-up 
    Create your own module
Succesfully added the Lambda function locally
? Do you want to edit your custom function now? Yes
Please edit the file in your editor: 
```

For Pre Sign-up lambda

```
exports.handler = (event) => {
    event.response.autoConfirmUser = true;
};
```

Continue in the terminal;

```
? Press enter to continue
Successfully added resource amplifyintegtest locally
```

4. If you are using the latest CLI, update cli.json to include `"useExperimentalPipelinedTransformer": false` to ensure that it will use the v1 transformer and then `amplify push`

5. Copy `amplifyconfiguration.json` over as `GraphQLWithIAMIntegrationTests-amplifyconfiguration.json` to `~/.aws-amplify/amplify-ios/testconfiguration/`

6. `amplify console auth` and choose `Identity Pool`. Click on **Edit Identity pool** and make note of IAM Role that is assigned for the Authenticated role.

7. Navigate to [AWS IAM Console](https://console.aws.amazon.com/iam/home) and select Roles, find the role attached to the Identity Pool's Authenticated role.

8. Click on Attach Policies, choose **AWSAppSyncInvokeFullAccess**, and attach the policy. This will allow users that are signed into the app to have access to invoke AppSync APIs.

You can now run the tests!
