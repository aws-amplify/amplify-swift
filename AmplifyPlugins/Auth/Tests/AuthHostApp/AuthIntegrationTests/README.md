#  Schema: AuthIntegrationTests - AWSCognitoAuthPlugin Integration tests

The following steps demonstrate how to setup the integration tests for auth plugin. 

## (Gen1) CLI setup

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

amplify push
```

This will create a amplifyconfiguration.json file in your local, copy that file to `~/.aws-amplify/amplify-ios/testconfiguration/` and rename as `AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json`.

For Auth Device tests:
Follow steps here (https://docs.amplify.aws/lib/auth/device_features/q/platform/ios/#configure-auth-category)[https://docs.amplify.aws/lib/auth/device_features/q/platform/ios/#configure-auth-category] and select "Always" for "Do you want to remember your user's devices?"


#  Schema: AuthGen2IntegrationTests

## Schema: AuthGen2IntegrationTests

The following steps demonstrate how to setup the integration tests for auth plugin using Amplify CLI (Gen2).

### Set-up

At the time this was written, it follows the steps from here https://docs.amplify.aws/gen2/deploy-and-host/fullstack-branching/mono-and-multi-repos/

1. From a new folder, run `npm create amplify@beta`. This uses the following versions of the Amplify CLI, see `package.json` file below.

```json
{
  ...
  "devDependencies": {
    "@aws-amplify/backend": "^0.13.0-beta.14",
    "@aws-amplify/backend-cli": "^0.12.0-beta.16",
    "aws-cdk": "^2.134.0",
    "aws-cdk-lib": "^2.134.0",
    "constructs": "^10.3.0",
    "esbuild": "^0.20.2",
    "tsx": "^4.7.1",
    "typescript": "^5.4.3"
  },
  "dependencies": {
    "aws-amplify": "^6.0.25"
  }
}

```
2. Update `amplify/auth/resource.ts`. The resulting file should look like this

```ts
import { defineAuth, defineFunction } from '@aws-amplify/backend';

/**
 * Define and configure your auth resource
 * @see https://docs.amplify.aws/gen2/build-a-backend/auth
 */
export const auth = defineAuth({
  loginWith: {
    email: true
  },
  triggers: {
    // configure a trigger to point to a function definition
    preSignUp: defineFunction({
      entry: './pre-sign-up-handler.ts'
    })
  }
});

```

```ts
import type { PreSignUpTriggerHandler } from 'aws-lambda';

export const handler: PreSignUpTriggerHandler = async (event) => {
  // your code here
  event.response.autoConfirmUser = true
  return event;
};
```

4. Commit and push the files to a git repository.

5. Navigate to the AWS Amplify console (https://us-east-1.console.aws.amazon.com/amplify/home?region=us-east-1#/)

6. Click on "Try Amplify Gen 2" button.

7. Choose "Option 2: Start with an existing app", and choose Github, and press Next.

8. Find the repository and branch, and click Next

9. Click "Save and deploy" and wait for deployment to finish.  

10. Generate the `amplify_outputs.json` configuration file

```
npx amplify generate config --branch main --app-id [APP_ID] --profile [AWS_PROFILE] --config-version 1
```

11. Copy the `amplify_outputs.json` file over to the test directory as `AWSCognitoAuthPluginIntegrationTests-amplify_outputs.json`. The tests will automatically pick this file up. Create the directories in this path first if it currently doesn't exist.

```
cp amplify_outputs.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSCognitoAuthPluginIntegrationTests-amplify_outputs.json
```

