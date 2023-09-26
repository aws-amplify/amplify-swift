## AWS CloudWatch Logging Integration Tests

The following steps demonstrate how to set up Logging. Auth category is also required to allow unauthenticated and authenticated access.

### Set-up

1. Configure app with Auth category

2. Copy `amplifyconfiguration.json` to a new file named `AWSCloudWatchLoggingPluginIntegrationTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`.

3. Configure the `amplifyconfiguration-logging.json` file 

4. Copy `amplifyconfiguration-logging.json` to a new file named `AWSCloudWatchLoggingPluginIntegrationTests-amplifyconfiguration-logging.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`.

3. You can now run all of the integration tests. 
