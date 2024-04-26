# AWS CloudWatch Logging Integration Tests

## Schema: AWSCloudWatchLoggingPluginIntegrationTests

The following steps demonstrate how to set up Logging. Auth category is also required to allow unauthenticated and authenticated access.

### Set-up

1. Configure app with Auth category using Amplify CLI

2. Copy `amplifyconfiguration.json` to a new file named `AWSCloudWatchLoggingPluginIntegrationTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`.

3. Configure the `amplifyconfiguration-logging.json` file (https://docs.amplify.aws/swift/build-a-backend/more-features/logging/set-up-logging/#initialize-amplify-logging)

4. Copy `amplifyconfiguration-logging.json` to a new file named `AWSCloudWatchLoggingPluginIntegrationTests-amplifyconfiguration-logging.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`.

5. You can now run all of the integration tests. 

## Schema: AWSCloudWatchLoggingPluginGen2IntegrationTests

The following steps demonstrate how to set up Logging. Auth category is also required to allow unauthenticated and authenticated access.

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

3. Commit and push the files to a git repository.

4. Navigate to the AWS Amplify console (https://us-east-1.console.aws.amazon.com/amplify/home?region=us-east-1#/)

5. Click on "Try Amplify Gen 2" button.

6. Choose "Option 2: Start with an existing app", and choose Github, and press Next.

7. Find the repository and branch, and click Next

8. Click "Save and deploy" and wait for deployment to finish.  

9. Generate the `amplify_outputs.json` configuration file

```
npx amplify generate config --branch main --app-id [APP_ID] --profile [AWS_PROFILE] --config-version 1
```

10. Copy the `amplify_outputs.json` file over to the test directory as `AWSCloudWatchLoggingPluginIntegrationTests-amplify_outputs.json`. The tests will automatically pick this file up. Create the directories in this path first if it currently doesn't exist.

```
cp amplify_outputs.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSCloudWatchLoggingPluginIntegrationTests-amplify_outputs.json
```

11. Configure the `amplifyconfiguration-logging.json` file (https://docs.amplify.aws/swift/build-a-backend/more-features/logging/set-up-logging/#initialize-amplify-logging)

12. Copy `amplifyconfiguration-logging.json` to a new file named `AWSCloudWatchLoggingPluginIntegrationTests-amplifyconfiguration-logging.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`.

13. You can now run all of the integration tests. 
