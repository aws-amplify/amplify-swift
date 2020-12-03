## Model Based GraphQL 

The following steps demonstrate how to set up a GraphQL endpoint with AppSync. The auth configured will be API key. The set up is used to run the tests in `GraphQLModelBasedTests.swift`


### Set-up

1. `amplify-init`

2. `amplify add api`


```perl
? Please select from one of the below mentioned services: `GraphQL`
? Provide API name: `<APIName>`
? Choose the default authorization type for the API `API key`
? Enter a description for the API key:
? After how many days from now the API key should expire (1-365): `365`
? Do you want to configure advanced settings for the GraphQL API `No, I am done`
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

## These are examples from https://docs.amplify.aws/cli/graphql-transformer/connection

# 1 - Project has a single optional Team
type Project1 @model {
  id: ID!
  name: String
  team: Team1 @connection
}

type Team1 @model {
  id: ID!
  name: String!
}

# 2 - Project with explicit field for team’s id
type Project2 @model {
  id: ID!
  name: String
  teamID: ID!
  team: Team2 @connection(fields: ["teamID"])
}

type Team2 @model {
  id: ID!
  name: String!
}

# 3 - Post Comment - keyName reference key directive

type Post3 @model {
  id: ID!
  title: String!
  comments: [Comment3] @connection(keyName: "byPost3", fields: ["id"])
}

type Comment3 @model
  @key(name: "byPost3", fields: ["postID", "content"]) {
  id: ID!
  postID: ID!
  content: String!
}

# 4 - Post Comment bi-directional belongs to

type Post4 @model {
  id: ID!
  title: String!
  comments: [Comment4] @connection(keyName: "byPost4", fields: ["id"])
}

type Comment4 @model
  @key(name: "byPost4", fields: ["postID", "content"]) {
  id: ID!
  postID: ID!
  content: String!
  post: Post4 @connection(fields: ["postID"])
}

# 5 Many to Many

type Post5 @model {
  id: ID!
  title: String!
  editors: [PostEditor5] @connection(keyName: "byPost5", fields: ["id"])
}

# Create a join model
type PostEditor5
  @model
  @key(name: "byPost5", fields: ["postID", "editorID"])
  @key(name: "byEditor5", fields: ["editorID", "postID"]) {
  id: ID!
  postID: ID!
  editorID: ID!
  post: Post5! @connection(fields: ["postID"])
  editor: User5! @connection(fields: ["editorID"])
}

type User5 @model {
  id: ID!
  username: String!
  posts: [PostEditor5] @connection(keyName: "byEditor5", fields: ["id"])
}

```

3.  `amplify push`
