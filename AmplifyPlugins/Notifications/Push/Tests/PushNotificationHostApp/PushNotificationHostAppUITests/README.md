# Push Notification plugin Integration Test

The following steps demostrate how to set up Push Notification Category. Auth category is also required for signing with AWS Pinpoint service and requesting with IAM credentials to allow unauthenticated and authenticated access.

## Set up Amplify

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

## Run Integration Tests

1. Start local server

We use a local server to let XCTestCase interact with host machine to run shell commands.

```sh
cd LocalServer
npm install
npm start
```

2. Run Integration test
