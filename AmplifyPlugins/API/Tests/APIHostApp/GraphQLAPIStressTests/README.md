## GraphQL API Stress Tests

The following steps demonstrate how to set up a GraphQL endpoint with AppSync. The auth configured will be API key.

The steps tested with Amplify CLI version 9.1.0. When running a later CLI version, you may also want to update the generated model files that are placed in the Models folder. 

Run `amplify codegen models` from your amplify app, compare and replace if needed the ones in the Models folder.


### Set-up

1. `amplify init`. Update `cli.json` values to use Transformer V1.

2. `amplify add api`

```perl
? Select from one of the below mentioned services: `GraphQL`
? Here is the GraphQL API that we will create. Select a setting to edit or continue Authorization modes: `API key (default, expiration time: 7 days from now)`
? Choose the default authorization type for the API `API key`
✔ Enter a description for the API key: · 
✔ After how many days from now the API key should expire (1-365): · `365`
? Configure additional auth types? `No`
? Here is the GraphQL API that we will create. Select a setting to edit or continue `Continue`
? Choose a schema template: `Blank Schema`
```
Edit the schema to the following:
```

type Post @model {
  id: ID!
  title: String!
  status: PostStatus!
  rating: Int
  content: String
}

enum PostStatus {
  ACTIVE
  INACTIVE
}

```

3.  `amplify push`

? Do you want to generate code for your newly created GraphQL API (Y/n) `N`

4. Copy `amplifyconfiguration.json` over as `AWSGraphQLAPIStressTests-amplifyconfiguration.json` to `~/.aws-amplify/amplify-ios/testconfiguration/`

```
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSGraphQLAPIStressTests-amplifyconfiguration.json
```
You can now run the tests!
