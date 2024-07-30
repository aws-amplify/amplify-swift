# Analytics Integration Tests

## Schema: AWSPinpointAnalyticsPluginIntegrationTests
 
The following steps demonstrate how to set up Analytics. Auth category is also required for signing with AWS Pinpoint service and requesting with IAM credentials to allow unauthenticated and authenticated access.

### Set-up

1. `amplify init`

2. `amplify add analytics`

```perl
? Select an Analytics provider: Amazon Pinpoint`
? Provide your pinpoint resource name `yourPinpointResourceName`
? Apps need autorization to send analytics events. Do you want to allow guests and unauthenticated users to send analytics events? (we recommend you allow this when getting started) `Yes`
```

3. `amplify push`

4. Copy `amplifyconfiguration.json` as `AWSPinpointAnalyticsPluginIntegrationTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`

```perl
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSPinpointAnalyticsPluginIntegrationTests-amplifyconfiguration.json
```

5. You can now run all of the integration tests. 

6. You can run `amplify console analytics` to check what happens at the backend. 

## Schema: AWSPinpointAnalyticsPluginGen2IntegrationTests

The following steps demonstrate how to set up Pinpoint and Auth using Amplify CLI Gen2. 

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
    email: true
  }
});

```

3. Update `amplify/backend.ts` to create the analytics stack (https://docs.amplify.aws/gen2/build-a-backend/add-aws-services/analytics/)

Add the following imports

```ts
import { Policy, PolicyStatement } from "aws-cdk-lib/aws-iam";
import { CfnApp } from "aws-cdk-lib/aws-pinpoint";
import { Stack } from 'aws-cdk-lib';
```

Create `backend` const

```ts
const backend = defineBackend({
  auth
});
```

Add the remaining code

```ts
const analyticsStack = backend.createStack("analytics-stack");

// create a Pinpoint app
const pinpoint = new CfnApp(analyticsStack, "Pinpoint", {
  name: "myPinpointApp",
});

// create an IAM policy to allow interacting with Pinpoint
const pinpointPolicy = new Policy(analyticsStack, "PinpointPolicy", {
  policyName: "PinpointPolicy",
  statements: [
    new PolicyStatement({
      actions: ["mobiletargeting:UpdateEndpoint", "mobiletargeting:PutEvents"],
      resources: [pinpoint.attrArn + "/*"],
    }),
  ],
});

// apply the policy to the authenticated and unauthenticated roles
backend.auth.resources.authenticatedUserIamRole.attachInlinePolicy(pinpointPolicy);
backend.auth.resources.unauthenticatedUserIamRole.attachInlinePolicy(pinpointPolicy);

// patch the custom Pinpoint resource to the expected output configuration
backend.addOutput({
  analytics: {
    amazon_pinpoint: {
      app_id: pinpoint.ref,
      aws_region: Stack.of(pinpoint).region,
    },
  },
});
```

4. Deploy the backend with npx amplify sandbox

For example, this deploys to a sandbox env and generates the amplify_outputs.json file.

```
npx amplify sandbox --config-out-dir ./config --profile [PROFILE]
```

5. Copy the `amplify_outputs.json` file over to the test directory as `AWSPinpointAnalyticsPluginIntegrationTests-amplify_outputs.json`. The tests will automatically pick this file up. Create the directories in this path first if it currently doesn't exist.

```
cp amplify_outputs.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSPinpointAnalyticsPluginIntegrationTests-amplify_outputs.json
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

