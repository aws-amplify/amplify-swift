#  Auth

## Schema: AuthHostedUIApp 

The following steps demonstrate how to setup the integration tests for auth plugin using Amplify CLI (Gen1).

1. Run `amplify init` and then `amplify add auth` and enable HostedUI.

2. Enter `myapp://` for the callback urls

3. `amplify push` to provision the backend

4. Copy the `amplifyconfiguration.json` file over to the test directory as `AWSCognitoAuthPluginHostedUIIntegrationTests-amplifyconfiguration.json`. The tests will automatically pick this file up. Create the directories in this path first if it currently doesn't exist.

```
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSCognitoAuthPluginHostedUIIntegrationTests-amplifyconfiguration.json
```

## Schema: AuthHostedUIAppGen2

The following steps demonstrate how to setup the integration tests for auth plugin using Amplify CLI (Gen2).

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

2. Update `amplify/auth/resource.ts`. The resulting file should look like this

```ts
import { defineAuth, defineFunction } from '@aws-amplify/backend';

/**
 * Define and configure your auth resource
 * @see https://docs.amplify.aws/gen2/build-a-backend/auth
 */
export const auth = defineAuth({
  loginWith: {
    email: true,
    externalProviders: {
      callbackUrls: ["myapp://"],
      logoutUrls: ["myapp://"],
    }
  },
  triggers: {
    // configure a trigger to point to a function definition
    preSignUp: defineFunction({
      entry: './pre-sign-up-handler.ts'
    })
  }
});
```

Add `amplify/auth/pre-sign-up-handler.ts` with the following: 

```ts
import type { PreSignUpTriggerHandler } from 'aws-lambda';

export const handler: PreSignUpTriggerHandler = async (event) => {
  // your code here
  event.response.autoConfirmUser = true
  return event;
};
```

3. Update `backend.ts`

```ts
import { defineBackend } from '@aws-amplify/backend';
import { auth } from './auth/resource';

const backend = defineBackend({
  auth
});
```

4. Deploy the backend with npx amplify sandbox

For example, this deploys to a sandbox env and generates the amplify_outputs.json file.

```
npx amplify sandbox --config-out-dir ./config --profile [PROFILE]
```

5. Copy the `amplify_outputs.json` file over to the test directory as `AWSCognitoAuthPluginHostedUIIntegrationTests-amplify_outputs.json`. The tests will automatically pick this file up. Create the directories in this path first if it currently doesn't exist.

```
cp amplify_outputs.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSCognitoAuthPluginHostedUIIntegrationTests-amplify_outputs.json
```

### Deploying from a branch (Optional)

If you want to be able utilize Git commits for deployments

1. Commit and push the files to a git repository.

2. Navigate to the AWS Amplify console (https://us-east-1.console.aws.amazon.com/amplify/home?region=us-east-1#/)

3. Click on "Try Amplify Gen 2" button.

4. Choose "Option 2: Start with an existing app", and choose Github, and press Next.

5. Find the repository and branch, and click Next

6. Click "Save and deploy" and wait for deployment to finish.  

7. Generate the `amplify_outputs.json` configuration file

```
npx amplify generate outputs --branch main --app-id [APP_ID] --profile [AWS_PROFILE]
```
