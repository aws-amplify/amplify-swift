## DataStore Integration Tests

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
? Configure conflict detection? `Yes`
? Select the default resolution strategy `Auto Merge`
? Choose a schema template: `Blank Schema`
? Do you want to edit the schema now? Y
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

# This is one of the default schemas provided when you run `amplify add api`
# > Do you have an annotated GraphQL schema? `No`
# > Choose a schema template: `One-to-many relationship (e.g., “Blogs” with “Posts” and “Comments”)`

# 6 - Blog Post Comment
type Blog6 @model {
  id: ID!
  name: String!
  posts: [Post6] @connection(keyName: "byBlog", fields: ["id"])
}

type Post6 @model @key(name: "byBlog", fields: ["blogID"]) {
  id: ID!
  title: String!
  blogID: ID!
  blog: Blog6 @connection(fields: ["blogID"])
  comments: [Comment6] @connection(keyName: "byPost", fields: ["id"])
}

type Comment6 @model @key(name: "byPost", fields: ["postID", "content"]) {
  id: ID!
  postID: ID!
  post: Post6 @connection(fields: ["postID"])
  content: String!
}

# Scalars, Lists, Enums

type ScalarContainer @model {
   id: ID!
   myString: String
   myInt: Int
   myDouble: Float
   myBool: Boolean
   myDate: AWSDate
   myTime: AWSTime
   myDateTime: AWSDateTime
   myTimeStamp: AWSTimestamp
   myEmail: AWSEmail
   myJSON: AWSJSON
   myPhone: AWSPhone
   myURL: AWSURL
   myIPAddress: AWSIPAddress
}

type ListIntContainer @model {
  id: ID!
  test: Int!
  nullableInt: Int
  intList: [Int!]!
  intNullableList: [Int!]
  nullableIntList: [Int]!
  nullableIntNullableList: [Int]
}

type ListStringContainer @model {
  id: ID!
  test: String!
  nullableString: String
  stringList: [String!]!
  stringNullableList: [String!]
  nullableStringList: [String]!
  nullableStringNullableList: [String]
}

type EnumTestModel @model {
  id: ID!
  enumVal: TestEnum!
  nullableEnumVal: TestEnum
  enumList: [TestEnum!]!
  enumNullableList: [TestEnum!]
  nullableEnumList: [TestEnum]!
  nullableEnumNullableList: [TestEnum]
}

enum TestEnum {
  VALUE_ONE
  VALUE_TWO
}

type NestedTypeTestModel @model {
  id: ID!
  nestedVal: Nested!
  nullableNestedVal: Nested
  nestedList: [Nested!]!
  nestedNullableList: [Nested!]
  nullableNestedList: [Nested]!
  nullableNestedNullableList: [Nested]
}

type Nested {
  valueOne: Int
  valueTwo: String
}

type CustomerOrder @model
   @key(fields: ["orderId","id"]) {
   id: ID!
   orderId: String!
   email: String!
}

```
3. If you are using the latest CLI, update cli.json to include `"useExperimentalPipelinedTransformer": false` and "transformerversion": 1, to ensure that it will use the v1 transformer.

4. `amplify push`

? Do you want to generate code for your newly created GraphQL API ? `No`

5. Copy `amplifyconfiguration.json` to a new file named `AWSDataStoreCategoryPluginIntegrationTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`

```
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSDataStoreCategoryPluginIntegrationTests-amplifyconfiguration.json
```


You should now be able to run all of the tests 
