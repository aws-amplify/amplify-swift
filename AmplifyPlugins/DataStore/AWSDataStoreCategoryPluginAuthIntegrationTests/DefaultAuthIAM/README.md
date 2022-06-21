## DataStore with Auth Integration Tests

The following steps demonstrate how to setup a GraphQL endpoint with AppSync and IAM.
This configuration is used to run the tests in `AWSDataStoreCategoryPluginAuthIntegrationTests.swift`.

### Set-up

1. `amplify init`. 

These tests were provisioned with V1 Transform:

- cli.json "transformerversion": 1
- cli.json "useexperimentalpipelinedtransformer": false

TODO: Update the schema and tests to use V2 Transform. 

2. `amplify add api`

```perl
? Select from one of the below mentioned services: GraphQL
? Here is the GraphQL API that we will create. Select a setting to edit or continue Authorization modes: API key (default, expiration time: 7 days fro
m now)
? Choose the default authorization type for the API IAM
? Configure additional auth types? No
? Here is the GraphQL API that we will create. Select a setting to edit or continue Conflict detection (required for DataStore): Disabled
? Enable conflict detection? Yes
? Select the default resolution strategy Auto Merge
? Here is the GraphQL API that we will create. Select a setting to edit or continue (Use arrow keys)
  Name: datastoreauintegiam
  Authorization modes: IAM (default)
  Conflict detection (required for DataStore): Enabled
  Conflict resolution strategy: Auto Merge
? Choose a schema template: Blank Schema
```

Copy the content of the schema from `AWSDataStoreCategoryPluginAuthIntegrationTests/DefaultAuthIAM/singleauth-iam-schema.graphql` into the newly created `schema.graphql` file

3. `amplify update api`
? Please select from one of the below mentioned services: `GraphQL`
? Select from the options below `Enable DataStore for entire API`

4. Add amplify auth

```
amplify add auth

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
    Custom Message
    Pre Sign-up
    [Choose as many that you would like to manually verify later]
? What functionality do you want to use for Custom Message
    Create your own module
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

For Custom Message and any other lambdas

```
// you can simply set them to log the input so you can verify valid and correct validationData/clientMetadata
exports.handler = (event) => {
    console.log("Reached custom message lambda"); 
};
```

Continue in the terminal;

```
? Press enter to continue
Successfully added resource amplifyintegtest locally

ampl

5. `amplify push`
```perl
? Are you sure you want to continue? `Yes`
? Do you want to generate code for your newly created GraphQL API `No`
```

6. Copy `amplifyconfiguration.json` to a new file named `AWSDataStoreCategoryPluginAuthIAMIntegrationTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`

```
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSDataStoreCategoryPluginAuthIAMIntegrationTests-amplifyconfiguration.json
```

7. Create `AWSDataStoreCategoryPluginAuthIAMIntegrationTests-credentials.json` inside the same folder with a json object containing `user1`, and `password`, used to create the cognito user in the userpool. In step 2, the cognito userpool is configured to allow users to sign up with their email as the username.

```json
{
    "user1": "<USER EMAIL>",
    "passwordUser1": "<PASSWORD>",
    "user2": "<USER2 EMAIL>",
    "passwordUser2": "<PASSWORD>"
}

```

### Creating users through AWS Console

8. `amplify console auth`
```perl
? Which console `User Pool`
```

9. Click on `Users and groups`, Sign up the two new users with the email and a temporary password. 

10. Click on App clients, and keep note of the app client web's `App client id`. This can be used the AWS AppSync console Queries.

11. `amplify console api`
Click on Queries tab, and click on Log in. This will prompt you to enter the app client id, username, and temporary password. After logging in successfully, it will ask you to enter a new password. Make sure those are the same as the one specified in the credentials json file from step 5. Do this for both users.
12. Some test cases require IAM to allow guest access. To do so run `amplify update auth` and follow the instructions

### Creating users through AWS CLI

8. Run the following commands

```
aws cognito-idp admin-create-user --user-pool-id [POOL_ID] --username [USER EMAIL]
aws cognito-idp admin-set-user-password --user-pool-id [POOL_ID] --username [USER EMAIL] --password [PASSWORD] --permanent
```

The `[POOL_ID]` can be found in `amplifyconfiguration.json` under `auth.plugin.awsCognitoAuthPlugin.CognitoUserPool.Default.PoolId`

Now you can run the AWSDataStoreCategoryPluginAuthIntegrationTests
