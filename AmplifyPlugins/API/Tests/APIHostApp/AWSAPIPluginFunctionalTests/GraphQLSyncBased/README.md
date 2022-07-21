## Sync Based GraphQL

The following steps demonstrate how to set up an GraphQL endpoint with AppSync that is provisioned with conflict resolution (Sync-based API). The auth configured will be API key. The set up is used to run the tests in `GraphQLSyncBasedTests.swift`.

### Set-up

1. `amplify init`

2. `amplify add api`

```perl
? Please select from one of the below mentioned services: `GraphQL`
? Provide API name: `<APIName>`
? Choose the default authorization type for the API `API key`
? Enter a description for the API key:
? After how many days from now the API key should expire (1-365): `365`
? Do you want to configure advanced settings for the GraphQL API `Yes, I want to make some additional changes.`
? Configure additional auth types? `No`
? Configure conflict detection? `Yes`
? Select the default resolution strategy `Optimistic Concurrency`
? Do you want to override default per model settings? `No`
? Do you have an annotated GraphQL schema? `Yes`
? Provide your schema file path: `schema.graphql`
```
When asked to provide the schema, create the `schema.graphql` file
```
enum PostStatus {
    PRIVATE
    DRAFT
    PUBLISHED
}

type Post @model {
    id: ID!
    title: String!
    content: String!
    createdAt: AWSDateTime!
    updatedAt: AWSDateTime
    draft: Boolean
    rating: Float
    status: PostStatus
    comments: [Comment] @connection(name: "PostComment")
}

type Comment @model {
    id: ID!
    content: String!
    createdAt: AWSDateTime!
    post: Post @connection(name: "PostComment")
}

type CustomerOrder @model
   @key(fields: ["orderId","id"]) {
   id: ID!
   orderId: String!
   email: String!
}
```

3. `amplify push`

4. Copy `amplifyconfiguration.json` over as `GraphQLSyncBasedTests-amplifyconfiguration.json` to `~/.aws-amplify/amplify-ios/testconfiguration/`
