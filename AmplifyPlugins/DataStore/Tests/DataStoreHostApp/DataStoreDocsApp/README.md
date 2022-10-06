## DataStore Docs App

Code snippets from https://docs.amplify.aws/lib/datastore/getting-started/q/platform/ios/ 

The API initially uses the following schema
```
input AMPLIFY { globalAuthRule: AuthRule = { allow: public } } # FOR TESTING ONLY!

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

CLI version: 9.2.1

GraphQL transformer version: 2

Once you have the backend provisioned, copy if over to the testconfiguration folder as `DataStoreDocsApp-amplifyconfiguration.json`

```
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/DataStoreDocsApp-amplifyconfiguration.json
```

Relational Model's schema is
```
enum PostStatus {
  ACTIVE
  INACTIVE
}

type Post @model @auth(rules: [{allow: public}]) {
  id: ID!
  title: String!
  rating: Int!
  status: PostStatus!
  # new field with @hasMany
  comments: [Comment] @hasMany
}

# new model
type Comment @model {
  id: ID!
  content: String
  post: Post @belongsTo
}
```

At the time this was written, Relational Models's Many-to-Many schema is

```
enum PostStatus {
  ACTIVE
  INACTIVE
}

type Post @model {
  id: ID!
  title: String!
  rating: Int
  status: PostStatus
  editors: [User] @manyToMany(relationName: "PostEditor")
}

type User @model {
  id: ID!
  username: String!
  posts: [Post] @manyToMany(relationName: "PostEditor")
}
```


