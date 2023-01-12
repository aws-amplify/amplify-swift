# DataStore Primary Key Integration Tests

The following steps demonstrate how to setup a GraphQL endpoint for testing Custom Primary Key (CPK) use cases.

### Set-up

The following steps have been tested with Amplify CLI v10.5.0.

1. `amplify init`

Make sure the `cli.json` has CPK feature enabled:

```
"respectprimarykeyattributesonconnectionfield": true
```

Amplify CLI version 10.5.0 is the minimum version that defaults the feature flag to true.

2. `amplify add api`

```perl
? Select from one of the below mentioned services: GraphQL
? Here is the GraphQL API that we will create. Select a setting to edit or continue Authorization modes: API key (default, expiration time: 7 days fro
m now)
? Choose the default authorization type for the API: "API key"
? Configure additional auth types? "No"
? Here is the GraphQL API that we will create. Select a setting to edit or continue Conflict detection (required for DataStore): Auto Merge
? Here is the GraphQL API that we will create. Select a setting to edit or continue (Use arrow keys)
  Name: datastorepkinteg
  Authorization modes: API key
  Conflict detection (required for DataStore): Enabled
  Conflict resolution strategy: Auto Merge
? Choose a schema template: Blank Schema
```

Copy the content of the schema from `AWSDataStoreCategoryPluginIntegrationTests/PrimaryKey/primarykey_schema.graphql` into the newly created `schema.graphql` file

3. `amplify update api`
? Please select from one of the below mentioned services: `GraphQL`
? Select from the options below `Enable DataStore for entire API`

4. `amplify push`
```perl
? Are you sure you want to continue? `Yes`
? Do you want to generate code for your newly created GraphQL API `No`
```

5. Copy `amplifyconfiguration.json` to a new file named `AWSDataStoreCategoryPluginPrimaryKeyIntegrationTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`

```
cp amplifyconfiguration.json AWSDataStoreCategoryPluginPrimaryKeyIntegrationTests-amplifyconfiguration.json
cp AWSDataStoreCategoryPluginPrimaryKeyIntegrationTests-amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/
```

Now you can run the AWSDataStoreCategoryPluginPrimaryKeyIntegrationTests


