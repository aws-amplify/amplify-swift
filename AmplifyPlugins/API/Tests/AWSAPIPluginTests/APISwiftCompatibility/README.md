# API.swift Compatibility

The Amplify CLI command `amplify codegen types` produces the API.swift file based on the GraphLQL introspection schema.

In Amplify CLI version x.x.x, the codegen process was updated to conditionally import the type definitions required to compile API.swift as a standalone file when AWSAPIPlugin is available for import, removing the need to depend on AWSAppSync SDK. This directory contains the unit tests to ensure that this file compiles and can work with AWSAPIPlugin.

## Schema

```
input AMPLIFY { globalAuthRule: AuthRule = { allow: public } } # FOR TESTING ONLY!

type Blog @model {
  id: ID!
  name: String!
  posts: [Post] @hasMany
  file: S3Object
}

type Post @model {
  id: ID!
  title: String!
  blog: Blog @belongsTo
  comments: [Comment] @hasMany
}

type Comment @model {
  id: ID!
  post: Post @belongsTo
  content: String!
}

type S3Object {
    bucket: String!
    key: String!
    region: String!
}
```

### API.swift

```
? Do you want to generate code for your newly created GraphQL API `Yes`
? Enter the file name pattern of graphql queries, mutations and subscriptions `graphql/**/*.graphql`
? Do you want to generate/update all possible GraphQL operations - queries, mutations and subscriptions `Yes`
? Enter maximum statement depth [increase from default if your schema is deeply nested] `2`
? Enter the file name for the generated code `API.swift`
```