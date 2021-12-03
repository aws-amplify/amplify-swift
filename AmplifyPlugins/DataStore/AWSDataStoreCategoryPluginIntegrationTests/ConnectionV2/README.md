## DataStore Integration V2 Tests

The following steps demonstrate how to set up DataStore with a conflict resolution enabled API through amplify CLI, with API key authentication mode. 


### Set-up

1. `amplify init` and choose `iOS` for type of app you are building

2. `amplify add api`

```perl
 Select from one of the below mentioned services: GraphQL
? Here is the GraphQL API that we will create. Select a setting to edit or continue Confl
ict detection (required for DataStore): Disabled
? Enable conflict detection? Yes
? Select the default resolution strategy Auto Merge
? Here is the GraphQL API that we will create. Select a setting to edit or continue Autho
rization modes: API key (default, expiration time: 7 days from now)
? Choose the default authorization type for the API API key
? Enter a description for the API key: 
? After how many days from now the API key should expire (1-365): 365
? Configure additional auth types? No
? Here is the GraphQL API that we will create. Select a setting to edit or continue Conti
nue
? Choose a schema template: Single object with fields (e.g., “Todo” with ID, name, descri
ption)

Then edit your schema

```
When asked to provide the schema, create the `schema.graphql` file
```
input AMPLIFY { globalAuthRule: AuthRule = { allow: public } } # FOR TESTING ONLY!

# Has One (Implicit Field)

type Project1V2 @model @auth(rules: [{allow: public}]) {
  id: ID!
  name: String
  team: Team1V2 @hasOne
}

type Team1V2 @model @auth(rules: [{allow: public}]) {
  id: ID!
  name: String!
}

# Has One (Explicit Field)

type Project2V2 @model @auth(rules: [{allow: public}]) {
  id: ID!
  name: String
  teamID: ID!
  team: Team2V2 @hasOne(fields: ["teamID"])
}

type Team2V2 @model @auth(rules: [{allow: public}]) {
  id: ID!
  name: String!
}

# Has Many `@hasMany` Implicit

type Post3aV2 @model {
  id: ID!
  title: String!
  comments: [Comment3aV2] @hasMany
}

type Comment3aV2 @model {
  id: ID!
  content: String!
}

# Has Many `@hasMany` Explicit

type Post3V2 @model @auth(rules: [{allow: public}]) {
  id: ID!
  title: String!
  comments: [Comment3V2] @hasMany(indexName: "byPost3", fields: ["id"])
}

type Comment3V2 @model @auth(rules: [{allow: public}]) {
  id: ID!
  postID: ID! @index(name: "byPost3", sortKeyFields: ["content"])
  content: String!
}

# 
type Post4V2 @model @auth(rules: [{allow: public}]) {
  id: ID!
  title: String!
  comments: [Comment4V2] @hasMany(indexName: "byPost4", fields: ["id"])
}

type Comment4V2 @model @auth(rules: [{allow: public}]) {
  id: ID!
  postID: ID! @index(name: "byPost4", sortKeyFields: ["content"])
  content: String!
  post: Post4V2 @belongsTo(fields: ["postID"])
}

type Blog6V2 @model @auth(rules: [{allow: public}]) {
  id: ID!
  name: String!
  posts: [Post6V2] @hasMany(indexName: "byBlog", fields: ["id"])
}

type Post6V2 @model @auth(rules: [{allow: public}]) {
  id: ID!
  title: String!
  blogID: ID! @index(name: "byBlog")
  blog: Blog6V2 @belongsTo(fields: ["blogID"])
  comments: [Comment6V2] @hasMany(indexName: "byPost", fields: ["id"])
}

type Comment6V2 @model @auth(rules: [{allow: public}]) {
  id: ID!
  postID: ID! @index(name: "byPost", sortKeyFields: ["content"])
  post: Post6V2 @belongsTo(fields: ["postID"])
  content: String!
}

type Blog7V2 @model {
  id: ID!
  name: String!
  posts: [Post7V2] @hasMany
}
type Post7V2 @model {
  id: ID!
  title: String!
  blog: Blog7V2 @belongsTo
  comments: [Comment7V2] @hasMany
}
type Comment7V2 @model {
  id: ID!
  content: String
  post: Post7V2 @belongsTo
}

```
3. `amplify push`

4. Copy `amplifyconfiguration.json` to a new file named `AWSDataStoreCategoryPluginIntegrationV2Tests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`
```
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSDataStoreCategoryPluginIntegrationV2Tests-amplifyconfiguration.json
```


You should now be able to run all of the tests 
