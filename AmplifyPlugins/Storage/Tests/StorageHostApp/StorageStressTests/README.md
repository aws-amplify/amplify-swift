## Storage Stress Tests

The following steps demonstrate how to set up Storage with unauthenticated and authenticated access.In the case of authenticated access, we will be using Cognito UserPools. 
This set up is used to run the tests in StorageStressTests.


### Set-up

1. `amplify init`

2. `amplify add storage`

```perl
? Please select from one of the below mentioned services: `Content (Images, audio, video, etc.)`
? You need to add auth (Amazon Cognito) to your project in order to add storage for user files. Do you want to add auth now? `Yes`
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
Do you want to configure Lambda Triggers for Cognito? 
    Yes
Which triggers do you want to enable for Cognito
    Pre Sign-up
What functionality do you want to use for Pre Sign-up 
    Create your own module
Succesfully added the Lambda function locally
Do you want to edit your custom function now? Yes
Please edit the file in your editor: 
```

For Pre Sign-up lambda

```
exports.handler = async (event, context) => {
  event.response.autoConfirmUser = true;
  return event
};
```

Continue in the terminal;

```
? Press enter to continue

Successfully added auth resource
? Please provide a friendly name for your resource that will be used to label this category in the project: `s3f34a5918`
? Please provide bucket name: `<BucketName>`
? Who should have access: `Auth and guest users`
? What kind of access do you want for Authenticated users? `create/update, read, delete`
? What kind of access do you want for Guest users? `create/update, read, delete`
? Do you want to add a Lambda Trigger for your S3 Bucket? `No`
```

3. `amplify push`


4. Copy `amplifyconfiguration.json` as `AWSAmplifyStressTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`

```
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSAmplifyStressTests-amplifyconfiguration.json
```
