# Push Notification plugin Integration Test

## Schema: PushNotificationsHostApp

The following steps demonstrate how to set up Push Notification Category. Auth category is also required for signing with AWS Pinpoint service and requesting with IAM credentials to allow unauthenticated and authenticated access.

### Set up Amplify

1. `amplify init`

2. `amplify add notifications`

    ```
    ✔ Choose the notification channel to enable · APNS |  Apple Push Notifications
    ⚠️ Adding notifications would add a Pinpoint resource from Analytics category if not already added
    ? Provide your pinpoint resource name: <default>
    ⚠️ Adding analytics would add the Auth category to the project if not already added.
    ? Apps need authorization to send analytics events. Do you want to allow guests and unauthenticated users to send analytics events? (we recommend you allow this when getting started) Yes
    ✅ Successfully added auth resource locally.
    ? Choose authentication method used for APNs Key
    ? The bundle id used for APNs Tokens:  <bundle identifier>
    ? The team id used for APNs Tokens:  <your team id>
    ? The key id used for APNs Tokens:  <your key id>
    ? The key file path (.p8):  <path to key>
    ✔ The APNS channel has been successfully enabled.
    ```

3. `amplify push`

4. Copy `amplifyconfiguration.json` to `AWSPushNotificationPluginIntegrationTest-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`

```
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSPushNotificationPluginIntegrationTest-amplifyconfiguration.json 
```

## Schema: PushNotificationsGen2HostApp

The following steps demonstrate to set up the same as above with Amplify CLI Gen2.

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

2. Update `amplify/backend.ts` to create the analytics stack (https://docs.amplify.aws/gen2/build-a-backend/add-aws-services/analytics/) and notifications stack

```ts
const pushNotificationStack = backend.createStack('pushNotification-analytics-stack')
const pinpoint = new CfnApp(pushNotificationStack, "PinPoint", {
  name: "pushNotification-pinPoint"
})

const pinpointPolicy = new Policy(pushNotificationStack, "PinpointPolicy", {
  policyName: "PinpointPolicy",
  statements: [
    new PolicyStatement({
      actions: ["mobiletargeting:*"],
      resources: [pinpoint.attrArn + "/*"],
    }),
  ],
});

backend.auth.resources.authenticatedUserIamRole.attachInlinePolicy(pinpointPolicy)
backend.auth.resources.unauthenticatedUserIamRole.attachInlinePolicy(pinpointPolicy)

backend.addOutput({
  analytics: {
    amazon_pinpoint: {
      app_id: pinpoint.ref,
      aws_region: Stack.of(pinpoint).region,
    }
  }
})

backend.addOutput({
  notifications: {
    amazon_pinpoint_app_id: pinpoint.ref,
    aws_region: Stack.of(pushNotificationStack).region,
    channels: ['APNS']
  }
})
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
  }
});

```

3. Deploy the backend with npx amplify sandbox

For example, this deploys to a sandbox env and generates the amplify_outputs.json file.

```
npx amplify sandbox --config-out-dir ./config --profile [PROFILE]
```

4. Copy `amplify_outputs.json` to `AWSPushNotificationPluginIntegrationTest-amplify_outputs.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`
```
cp amplify_outputs.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSPushNotificationPluginIntegrationTest-amplify_outputs.json 
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

## Run Integration Tests

1. Start local server

We use a local server to let XCTestCase interact with host machine to run shell commands.

```sh
cd LocalServer
npm install
npm start
```

2. Run Integration test
