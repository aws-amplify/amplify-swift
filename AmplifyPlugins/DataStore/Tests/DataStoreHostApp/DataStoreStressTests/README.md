## DataStore Stress Tests

The following steps demonstrate how to set up DataStore with a conflict resolution enabled API through amplify CLI, with API key authentication mode. 


### Set-up

1. `amplify init` and choose `iOS` for type of app you are building

2. `amplify add api`

```perl
? Please select from one of the below mentioned services: `GraphQL`
? Provide API name: `apiName`
? Choose the default authorization type for the API `API key`
? Enter a description for the API key:
? After how many days from now the API key should expire (1-365): `365`
? Do you want to configure advanced settings for the GraphQL API `Yes, I want to make some additional changes.`
? Configure additional auth types? `No`
? Choose a schema template: `Blank Schema`
? Do you want to edit the schema now? Y
```
When asked to provide the schema, create the `schema.graphql` file
```

type Post @model @auth(rules: [{ allow: public }]) {
   id: ID!
   title: String!
   status: PostStatus!
   content: String!
 }
 
 enum PostStatus {
   ACTIVE
   INACTIVE
 }

```

3. `amplify push`

4. Copy `amplifyconfiguration.json` to a new file named `AWSAmplifyStressTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`

```
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSAmplifyStressTests-amplifyconfiguration.json
```

You should now be able to run all of the tests 
