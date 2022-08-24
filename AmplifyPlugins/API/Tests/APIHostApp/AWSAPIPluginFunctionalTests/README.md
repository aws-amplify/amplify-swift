## Model Based GraphQL 

The following steps demonstrate how to set up a GraphQL endpoint with AppSync. The auth configured will be API key.

The steps tested with Amplify CLI version 9.1.0. When running a later CLI version, you may also want to update the generated model files that are placed in the Models folder. 

Run `amplify codegen models` from your amplify app, compare and replace if needed the ones in the Models folder.


### Set-up

1. `amplify init`. Update `cli.json` values to use Transformer V1.

- `"useexperimentalpipelinedtransformer": false`
- `"transformerversion": 1`

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
enum PostStatus {
    PRIVATE
    DRAFT
    PUBLISHED
}

type Post @model @auth(rules: [{ allow: public }]) {
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

type Comment @model @auth(rules: [{ allow: public }]) {
    id: ID!
    content: String!
    createdAt: AWSDateTime!
    post: Post @connection(name: "PostComment")
}

## These are examples from https://docs.amplify.aws/cli/graphql-transformer/connection

# 1 - Project has a single optional Team
type Project1 @model @auth(rules: [{ allow: public }]) {
  id: ID!
  name: String
  team: Team1 @connection
}

type Team1 @model @auth(rules: [{ allow: public }]) {
  id: ID!
  name: String!
}

# 2 - Project with explicit field for team's id
type Project2 @model @auth(rules: [{ allow: public }]) {
  id: ID!
  name: String
  teamID: ID!
  team: Team2 @connection(fields: ["teamID"])
}

type Team2 @model @auth(rules: [{ allow: public }]) {
  id: ID!
  name: String!
}

# 3 - Post Comment - keyName reference key directive

type Post3 @model @auth(rules: [{ allow: public }]) {
  id: ID!
  title: String!
  comments: [Comment3] @connection(keyName: "byPost3", fields: ["id"])
}

type Comment3 @model @auth(rules: [{ allow: public }])
  @key(name: "byPost3", fields: ["postID", "content"]) {
  id: ID!
  postID: ID!
  content: String!
}

# 4 - Post Comment bi-directional belongs to

type Post4 @model @auth(rules: [{ allow: public }]) {
  id: ID!
  title: String!
  comments: [Comment4] @connection(keyName: "byPost4", fields: ["id"])
}

type Comment4 @model @auth(rules: [{ allow: public }])
  @key(name: "byPost4", fields: ["postID", "content"]) {
  id: ID!
  postID: ID!
  content: String!
  post: Post4 @connection(fields: ["postID"])
}

# 5 Many to Many

type Post5 @model @auth(rules: [{ allow: public }]) {
  id: ID!
  title: String!
  editors: [PostEditor5] @connection(keyName: "byPost5", fields: ["id"])
}

# Create a join model
type PostEditor5 @model @auth(rules: [{ allow: public }])
  @key(name: "byPost5", fields: ["postID", "editorID"])
  @key(name: "byEditor5", fields: ["editorID", "postID"]) {
  id: ID!
  postID: ID!
  editorID: ID!
  post: Post5! @connection(fields: ["postID"])
  editor: User5! @connection(fields: ["editorID"])
}

type User5 @model @auth(rules: [{ allow: public }]) {
  id: ID!
  username: String!
  posts: [PostEditor5] @connection(keyName: "byEditor5", fields: ["id"])
}

# This is one of the default schemas provided when you run `amplify add api`
# > Do you have an annotated GraphQL schema? `No`
# > Choose a schema template: `One-to-many relationship (e.g., “Blogs” with “Posts” and “Comments”)`

# 6 - Blog Post Comment
type Blog6 @model @auth(rules: [{ allow: public }]) {
  id: ID!
  name: String!
  posts: [Post6] @connection(keyName: "byBlog", fields: ["id"])
}

type Post6 @model @auth(rules: [{ allow: public }])
@key(name: "byBlog", fields: ["blogID"]) {
  id: ID!
  title: String!
  blogID: ID!
  blog: Blog6 @connection(fields: ["blogID"])
  comments: [Comment6] @connection(keyName: "byPost", fields: ["id"])
}

type Comment6 @model @auth(rules: [{ allow: public }])
@key(name: "byPost", fields: ["postID", "content"]) {
  id: ID!
  postID: ID!
  post: Post6 @connection(fields: ["postID"])
  content: String!
}

# Scalars, Lists, Enums

type ScalarContainer @model @auth(rules: [{ allow: public }]) {
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

type ListIntContainer @model @auth(rules: [{ allow: public }]) {
  id: ID!
  test: Int!
  nullableInt: Int
  intList: [Int!]!
  intNullableList: [Int!]
  nullableIntList: [Int]!
  nullableIntNullableList: [Int]
}

type ListStringContainer @model @auth(rules: [{ allow: public }]) {
  id: ID!
  test: String!
  nullableString: String
  stringList: [String!]!
  stringNullableList: [String!]
  nullableStringList: [String]!
  nullableStringNullableList: [String]
}

type EnumTestModel @model @auth(rules: [{ allow: public }]) {
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

type NestedTypeTestModel @model @auth(rules: [{ allow: public }]){
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

```

3.  `amplify push`
? Do you want to generate code for your newly created GraphQL API (Y/n) `N`

4. Copy `amplifyconfiguration.json` over as `GraphQLModelBasedTests-amplifyconfiguration.json` to `~/.aws-amplify/amplify-ios/testconfiguration/`

```
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/GraphQLModelBasedTests-amplifyconfiguration.json
```
You can now run the tests!