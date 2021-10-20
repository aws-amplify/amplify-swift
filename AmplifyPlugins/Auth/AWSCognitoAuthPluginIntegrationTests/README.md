#  AWSCognitoAuthPlugin Integration tests

The following steps demonstrate how to setup the integration tests for auth plugin. 

## CLI setup

The integration test require auth configured with AWS Cognito User Pool and AWS Cognito Identity Pool. 

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

amplify push
```

This will create a amplifyconfiguration.json file in your local, copy that file to `~/.aws-amplify/amplify-ios/testconfiguration/` and rename as `AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json`.

Next create `AWSCognitoAuthPluginIntegrationTests-credentials.json` and add it to the same folder path, with the following values:

```
{
    "test_email_1": [YOUR_EMAIL],
    "test_email_2": [ANOTHER_EMAIL]
}
```

The email should be a valid email you can use for testing, for example for making sure you receive a confirmation code when updating user's attributes with an email.

After running tests pass that in `metadata`, you can verify the corresponding lambdas have been trigger with payloads containing this data.
