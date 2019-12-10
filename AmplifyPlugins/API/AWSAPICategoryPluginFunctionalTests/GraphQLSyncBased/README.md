## Sync Based GraphQL

provisioned with sync

TODO: Currently these tests work because it is checking that the models are syncable. 
This will be updated to check if the datastore plugin is configured.

/*
1. Set up with this schema
```
type Post @model {
    id: ID!
    title: String!
    content: String!
    createdAt: AWSDateTime!
    updatedAt: AWSDateTime
    draft: Boolean
    rating: Float
    comments: [Comment] @connection(name: "PostComment")
}

type Comment @model {
    id: ID!
    content: String!
    createdAt: AWSDateTime!
    post: Post @connection(name: "PostComment")
}
2. Sync Enabled
*/
