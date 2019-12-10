## Model Based GraphQL 

provisioned without Sync

/*
 The backend is set up using this schema:
 ```
 type Post @model {
     id: ID!
     title: String!
     content: String!
     createdAt: AWSDateTime!
     updatedAt: AWSDateTime
     draft: Boolean
     rating: Float
     commentNoSyncs: [Comment] @connection(name: "PostComment")
 }

 type Comment @model {
     id: ID!
     content: String!
     createdAt: AWSDateTime!
     post: Post @connection(name: "PostComment")
 }

 ```

 Bootstrapping backend

 - for subscriptions, this was done in us-west-2 for the new gogi endpoints.
 - use the schema when adding graphQL API
 - choose API key

 Example CLI workflow:
 `amplify add api`
    ? Please select from one of the below mentioned services `GraphQL`
    ? Provide API name: `modelbasedapi`
    ? Choose the default authorization type for the API `API key`
    ? Enter a description for the API key: `apikey`
    ? After how many days from now the API key should expire (1-365): `180`
    ? Do you want to configure advanced settings for the GraphQL API `No, I am done.`
    ? Do you have an annotated GraphQL schema? `Yes`
    ? Provide your schema file path: schema.graphql

 `amplify push`
    ? Do you want to generate code for your newly created GraphQL API `Yes`
    ? Enter the file name pattern of graphql queries, mutations and subscriptions `graphql/**/*.graphql`
    ? Do you want to generate/update all possible GraphQL operations - queries, mutations and subscriptions `Yes`
    ? Enter maximum statement depth [increase from default if your schema is deeply nested] `2`
    ? Enter the file name for the generated code `API.swift`


The models exist in AmplifyTestCommon/Models/Post.swift and Comment.Swift, we use these for testing

 {
     "UserAgent": "aws-amplify/cli",
     "Version": "0.1.0",
     "IdentityManager": {
         "Default": {}
     },
     "AppSync": {
         "Default": {
             "ApiUrl": "https://xxxx.appsync-api.us-west-2.amazonaws.com/graphql",
             "Region": "us-west-2",
             "AuthMode": "API_KEY",
             "apiKey": "da2-xxx",
             "ClientDatabasePrefix": "modelbasedapi_API_KEY"
         }
     }
 }

 */
