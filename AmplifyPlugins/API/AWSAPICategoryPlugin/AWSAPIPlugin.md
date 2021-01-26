## Model-based GraphQL API queries

APIPlugin at its core provides functionality to make requests to a GraphQL service. There are key developer use cases that can be achieved when using Amplify's `Model` types generated from Amplify CLI after provisioning a GraphQL AppSync service through the `amplify add api` command . The usability of the API (`Amplify.API.query`, `Amplify.API.mutate`, and `Amplify.API.subscribe`) is coupled with the `GraphQLRequest` builders (`.get`, `.create`, etc) to provide a simple way to perform operations on their model or to retrieve instances of the model. The following goes over the algorithms used to perform successful operations for retrieving a model, a model with associations, and a list of models.

1. As a developer, I want to retrieve a simple model object. 
```swift
Amplify.API.query(.get(SimpleModel.self, byId: id)

// A Simple Model
struct SimpleModel: Model {
  let id: String
}
```
- A `GraphQLRequest` is created from `.get(SimpleModel.self, byId: id)` containing the request payload such as a document, variables, and a response type. 
- The document contains the selection set that indicates how much data (which fields of the model) is retrieved in the response and the response type provides the decoders that handles decoding the data to the model instance. 
- `AWSGraphQLOperation` will serializes the request and perform the network call to the AppSync service.
- Upon getting a successful response from the service, the data portion of the response which represents the model instance, is extracted by `GraphQLResponseDecoder`.
- The model instance data is decoded to the response type. As an end result, the instance of the model is returned.

2. As a developer, I want to retrieve a list of simple model objects.
```swift
Amplify.API.query(.paginatedList(SimpleModel.self)
```
- `.paginatedList(SimpleModel.self)` will create a `GraphQLRequest` with selection set containing "items" and "nextToken", response type `List<SimpleModel>`, and variables containing the `limit` of 1000.
- `GraphQLResponseDecoder` will detect that the response type is a `List` by checking against `ModelListMarker`, before encapsulating the original request and response using an `AppSyncListPayload`, and decoding the `AppSyncListPayload` to the list type.
- `List`'s custom decoder will use the `ModelListDecoderRegistry` to find a registered decoder and attempt to decode the response to retrieve an `ModelListProvider`.
- `AppSyncListDecoder` is registered at config time by the plugin to provide runtime decoding functionality, it checks that the data can be successfully decoded to an `AppSyncListPayload`, extracting the original request variables and instantiating a loaded list with the response data. 
The developer has the list of models, and can check if there are subsequent pages to retrieve as indicated in response's nextToken field, and can retrieve the next set of comments with the same `limit` and `filter` as the original request.

```swift
if models.hasNextPage() {
   models.getNextPage()
}
```

3. As a developer, I want to retrieve a model that contains associations to other models.
```swift
Amplify.API.query(.get(Post.self, byId: id)

// A `Post` model contains an association to the `Comment` as an "has many" array association.
struct Post: Model {
   let id: String
   let comments: List<Comment>?
}
// The `Comment` belongs to a `Post.
struct Comment: Model {
   let id: String
   let post: Post?
}
```
- The selection set can contain multiple levels of data (the first level being the post, and second level being the list of comments), however `get(Post.self, byId: id)` controls this and only creates a selection set containng the first level to be retrieved. This provides a scalable approach to retrieve models with an "not loaded" association, and allow the developer to lazy load the assocations later.
- `GraphQLResponseDecoder` will decode the "post" response post data to a `JSONValue` object as an intermediate step to allow modifications to the data.
- The object is analyzed according to the model schema, association data (post.id and "post" field name) is stored at "comments" by creating and storing `AppSyncModelMetadata` at the "comments" key.
- The object is then serialized and then decoded to the post instance. The `Post` decoder will instantiate the fields as normally while the "comments" field will be decoded by the `List<Comment>` that delegates its logic to the `AppSyncModelListDecoder`. 
- `AppSyncListDecoder` checks that the data can be successfully decoded to an `AppSyncModelMetadata` and stores this information in an `AppSyncListProvider` when instantiating a "not loaded" list with association data.
The developer has the post instance and can lazy load the comments upon accessing it.
```swift
foreach comment in post.comments {
   /// comments is loaded before the first element is returned.
}
```
- The comments are implicitly loaded upon access by taking the association data and performing a query to get the list of comments by its post id. Storing the result in the list object, and returning that to the caller that is performing the access.
The implicit load is the same as performing an explicit call to retrieve a list of models, given a limit and condition.
```swift
Amplify.API.query(.paginatedList(Comment.self, limit: 100, where: Comment.keys.post == post.id))
```

4. As a developer, I can customize my request to retrieve multiple levels of data at once
```swift
let document = """
  query getBlog($id: ID!) {
    getBlog(id: $id) {
      id
      post {
        items {
          id
          comments {
            items {
              id
            }
            nextToken
          }
        }
        nextToken
      }
    }
  }
  """
```
- `GraphQLResponseDecoder` will skip argumenting the response data at "post" and "comments" with association data since the response data already contains the payload to be decoded to the list.
- `AppSyncListDecoder` checks that the data can be successfully decoded to `AppSyncListResponse` and instantaites a loaded list of post and list of comments respectively in the chain of decoders. 

This advanced use case is not without caveats on integrity of the subsequent APIs calls performed from the list object. For example, `hasNextPage` relies on the selection set to contain `nextToken`, so if this is excluded from the selection set, then `hasNextPage` will always return false. `getNextPage` does not retrieve the next page according to the associated parent since association data was never added to the list provider. By providing this successful decoding flow `AppSyncListResponse`, the data represents more of a snapshot, and assumes that the developer understand what they are trying to achieve with the customization. Alternatively, developers can go to the full extent of modifying the response type as well to `AppSyncListResponse` to decode exactly what the AppSync service returns in the response.