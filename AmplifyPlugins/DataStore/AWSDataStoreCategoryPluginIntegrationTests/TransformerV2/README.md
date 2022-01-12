## DataStore Integration V2 Tests

The following steps demonstrate how to set up DataStore with a conflict resolution enabled API through amplify CLI, with API key authentication mode. 


### Set-up

1. `amplify init` and choose `iOS` for type of app you are building

2. `amplify add api`

```perl
 Select from one of the below mentioned services: `GraphQL`
? Enable conflict detection? Yes
? Select the default resolution strategy `Auto Merge`
? Here is the GraphQL API that we will create. Select a setting to edit or continue Authorization modes: `API key (default, expiration time: 7 days from now)`
? Choose the default authorization type for the API API key
? Enter a description for the API key: 
? After how many days from now the API key should expire (1-365): `365`
? Configure additional auth types? `No`
? Here is the GraphQL API that we will create. Select a setting to edit or continue Continue
? Choose a schema template: `Single object with fields (e.g., “Todo” with ID, name, description)`

Then edit your schema and replace it with **AmplifyTestCommon/Models/TransformerV2/schema.graphql**

3. `amplify push`

4. Verify that the changes were pushed with the transformer V2 feature flags enabled. In `amplify/cli.json`, the feature flags values should be the following
```
features.graphqltransformer.transformerversion: 2
features.graphqltransformer.useexperimentalpipelinedtransformer: true
```

5. Copy `amplifyconfiguration.json` to a new file named `AWSDataStoreCategoryPluginIntegrationV2Tests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`
```
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSDataStoreCategoryPluginIntegrationV2Tests-amplifyconfiguration.json
```


You should now be able to run all of the tests under the TransformerV2 folder
