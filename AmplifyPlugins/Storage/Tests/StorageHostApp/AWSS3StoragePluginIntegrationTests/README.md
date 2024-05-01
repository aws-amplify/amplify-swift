# Storage Integration Tests

## Schema: AWSS3StoragePluginIntegrationTests

The following steps demonstrate how to set up Storage with unauthenticated and authenticated access.In the case of authenticated access, we will be using Cognito UserPools. Both unauthenticated and authenticated configurations are used to execute the AWSS3StoragePluginFunctionalTests. This set up is used to run the tests in AWSS3StoragePluginFunctionalTests


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


4. Copy `amplifyconfiguration.json` as `AWSS3StoragePluginTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`

```
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSS3StoragePluginTests-amplifyconfiguration.json
```

You should now be able to run all of the tests from AWSS3StoragePluginAccessLevelTests 

## Schema: AWSS3StoragePluginGen2IntegrationTests


### Set-up

At the time this was written, it follows the steps from here https://docs.amplify.aws/gen2/deploy-and-host/fullstack-branching/mono-and-multi-repos/

1. From a new folder, run `npm create amplify@beta`. This uses the following versions of the Amplify CLI, see `package.json` file below.

```json
{
  ...
  "devDependencies": {
    "@aws-amplify/backend": "^0.15.0",
    "@aws-amplify/backend-cli": "^0.15.0",
    "aws-cdk": "^2.139.0",
    "aws-cdk-lib": "^2.139.0",
    "constructs": "^10.3.0",
    "esbuild": "^0.20.2",
    "tsx": "^4.7.3",
    "typescript": "^5.4.5"
  },
  "dependencies": {
    "aws-amplify": "^6.2.0"
  },
}
```

2. Update `amplify/storage/resource.ts`. The resulting file should look like this

```ts
import { defineStorage } from '@aws-amplify/backend';

export const storage = defineStorage({
    name: 'myProjectFiles',
    access: (allow) => ({
      'public/*': [
        allow.guest.to(['read', 'write', 'delete']),
        allow.authenticated.to(['read', 'write', 'delete']),
      ],
      'protected/{entity_id}/*': [
        allow.guest.to(['read']),
        allow.authenticated.to(['read']),
        allow.entity('identity').to(['read', 'write', 'delete'])
      ],
      'private/{entity_id}/*': [allow.entity('identity').to(['read', 'write', 'delete'])]
    })
  });
```

Update `amplify/auth/resource.ts`. The resulting file should look like this

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

`pre-sign-up-handler.ts`

```ts
import type { PreSignUpTriggerHandler } from 'aws-lambda';

export const handler: PreSignUpTriggerHandler = async (event) => {
  // your code here
  event.response.autoConfirmUser = true
  return event;
};
```

`backend.ts`

```ts
const { cfnUserPool } = backend.auth.resources.cfnResources
cfnUserPool.usernameAttributes = []

cfnUserPool.addPropertyOverride(
  "Policies",
  {
    PasswordPolicy: {
      MinimumLength: 10,
      RequireLowercase: false,
      RequireNumbers: true,
      RequireSymbols: true,
      RequireUppercase: true,
      TemporaryPasswordValidityDays: 20,
    },
  }
);
```

4. Deploy the backend with npx amplify sandbox

For example, this deploys to a sandbox env and generates the amplify_outputs.json file.

```
npx amplify sandbox --config-out-dir ./config --profile [PROFILE]
```

5. Copy the `amplify_outputs.json` file over to the test directory as `AWSS3StoragePluginTests-amplify_outputs.json`. The tests will automatically pick this file up. Create the directories in this path first if it currently doesn't exist.

```
cp amplify_outputs.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSS3StoragePluginTests-amplify_outputs.json
```

### Deploying from a branch (Optional)

If you want to be able utilize Git commits for deployments

4. Commit and push the files to a git repository.

5. Navigate to the AWS Amplify console (https://us-east-1.console.aws.amazon.com/amplify/home?region=us-east-1#/)

6. Click on "Try Amplify Gen 2" button.

7. Choose "Option 2: Start with an existing app", and choose Github, and press Next.

8. Find the repository and branch, and click Next

9. Click "Save and deploy" and wait for deployment to finish.  

10. Generate the `amplify_outputs.json` configuration file

```
npx amplify generate outputs --branch main --app-id [APP_ID] --profile [AWS_PROFILE]
```
