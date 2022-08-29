## Analytics Integration Tests

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
