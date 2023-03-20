## DataStore Lazy Load Integration Tests

### Prerequisites
- AWS CLI
- Version used: `amplify -v` => ``

### Set-up

1. `amplify init`

These tests were provisioned with V2 Transform, CPK enabled, and with the lazy loading feature flag.
Review or make updates to `cli.json`
- "transformerversion":2 
- "respectprimarykeyattributesonconnectionfield": true
- "generateModelsForLazyLoadAndCustomSelectionSet": true 

2. `amplify add api`

- Choose conflict resolution for DataStore
- Use API Key
- Use the `lazyload-schema.graphql` from this test directory.

3. `amplify push`

```perl
? Are you sure you want to continue? `Yes`
? Do you want to generate code for your newly created GraphQL API `No`
```

4. Copy `amplifyconfiguration.json` to a new file named `AWSDataStoreCategoryPluginLazyLoadIntegrationTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`

```perl
cp amplifyconfiguration.json AWSDataStoreCategoryPluginLazyLoadIntegrationTests-amplifyconfiguration.json
cp AWSDataStoreCategoryPluginLazyLoadIntegrationTests-amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/
```
