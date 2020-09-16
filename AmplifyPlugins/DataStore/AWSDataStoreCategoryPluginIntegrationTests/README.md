## DataStore Integration Tests

The following steps demonstrate how to set up DataStore with a conflict resolution enabled API through amplify CLI, with API key authentication mode. 


### Set-up

1. `amplify init` and choose `iOS` for type of app you are building

2. Create the `schema.graphql` file in the same directory and use the schema from [AmplifyTestCommon](https://github.com/aws-amplify/amplify-ios/blob/main/AmplifyTestCommon/Models/schema.graphql)

3. `amplify add api`

```perl
? Please select from one of the below mentioned services: `GraphQL`
? Provide API name: `apiName`
? Choose the default authorization type for the API `API key`
? Enter a description for the API key:
? After how many days from now the API key should expire (1-365): `365`
? Do you want to configure advanced settings for the GraphQL API `Yes, I want to make some additional changes.`
? Configure additional auth types? `No`
? Configure conflict detection? `Yes`
? Select the default resolution strategy `Auto Merge`
? Do you have an annotated GraphQL schema? `Yes`
? Provide your schema file path: `schema.graphql`
```

4. `amplify push`

5. Copy `amplifyconfiguration.json` over to the Config folder

You should now be able to run all of the tests 
