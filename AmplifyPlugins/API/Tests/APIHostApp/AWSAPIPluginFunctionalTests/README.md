## Schema: AWSAPIPluginFunctionalTests 

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

```

3.  `amplify push`
 
```
? Do you want to generate code for your newly created GraphQL API (Y/n) `Y`
```
Generate the API.swift file. This file has already been copied over to the tests. Use it if you need to replace the existing one if there are any updates to the CLI/codegen version. 

Keep in mind that the API.swift file in the tests has been manually modified to encapsulate the types under `APISwift` struct. This is to avoid type collision with the modelgen types.

4. Copy `amplifyconfiguration.json` over as `GraphQLModelBasedTests-amplifyconfiguration.json` to `~/.aws-amplify/amplify-ios/testconfiguration/`

```
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/GraphQLModelBasedTests-amplifyconfiguration.json
```
You can now run the tests!


## Schema: AWSAPIPluginGen2FunctionalTests

The following steps demonstrate how to set up an GraphQL endpoint with AppSync using Amplify CLI (Gen2). The auth configured will be API Key.

### Set-up

At the time this was written, it follows the steps from here https://docs.amplify.aws/gen2/deploy-and-host/fullstack-branching/mono-and-multi-repos/

1. From a new folder, run `npm create amplify@beta`. This uses the following versions of the Amplify CLI, see `package.json` file below.

```json
{
  ...
  "devDependencies": {
    "@aws-amplify/backend": "^0.13.0-beta.14",
    "@aws-amplify/backend-cli": "^0.12.0-beta.16",
    "aws-cdk": "^2.134.0",
    "aws-cdk-lib": "^2.134.0",
    "constructs": "^10.3.0",
    "esbuild": "^0.20.2",
    "tsx": "^4.7.1",
    "typescript": "^5.4.3"
  },
  "dependencies": {
    "aws-amplify": "^6.0.25"
  }
}

```
2. Update `amplify/data/resource.ts` to allow `public` access. This allows using API Key as the auth type to perform CRUD operations against the Comment and Post models. The resulting file should look like this

```ts
const schema = a.schema({
  Post: a
    .model({
      title: a.string().required(),
      content: a.string().required(),
      draft: a.boolean(),
      rating: a.float(),
      status: a.enum(["PRIVATE", "DRAFT", "PUBLISHED"]),
      comments: a.hasMany('Comment')
    })
    .authorization([a.allow.public()]),
  Comment: a
    .model({
      content: a.string().required(),
      post: a.belongsTo('Post'),
    })
    .authorization([a.allow.public()]),
});
```

3. (Optional) Update the API Key expiry to the maximum. This should be done if this backend is used for CI testing.

```
export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: 'apiKey',
    // API Key is used for a.allow.public() rules
    apiKeyAuthorizationMode: {
      expiresInDays: 365,
    },
  },
});
```

4. Deploy the backend with npx amplify sandbox

For example, this deploys to a sandbox env and generates the amplify_outputs.json file.

```
npx amplify sandbox --config-out-dir ./config --config-version 1 --profile [PROFILE]
```

5. Copy the `amplify_outputs.json` file over to the test directory as `GraphQLModelBasedTests-amplify_outputs.json`. The tests will automatically pick this file up. Create the directories in this path first if it currently doesn't exist.

```
cp amplify_outputs.json ~/.aws-amplify/amplify-ios/testconfiguration/GraphQLModelBasedTests-amplify_outputs.json
```

6. (Optional) The code generated model files are already checked into the tests so you will only have to re-generate them if you are expecting modifications to them and replace the existing ones checked in.

```
npx amplify generate graphql-client-code --format=modelgen --model-target=swift --branch main --app-id [APP_ID] --profile [AWS_PROFILE]
```

### Deploying from a branch (Optional)

If you want to be able utilize Git commits for deployments

1. Commit and push the files to a git repository.

2. Navigate to the AWS Amplify console (https://us-east-1.console.aws.amazon.com/amplify/home?region=us-east-1#/)

3. Click on "Try Amplify Gen 2" button.

4. Choose "Option 2: Start with an existing app", and choose Github, and press Next.

5. Find the repository and branch, and click Next

6. Click "Save and deploy" and wait for deployment to finish.  

7. Generate the `amplify_outputs.json` configuration file

```
npx amplify generate config --branch main --app-id [APP_ID] --profile [AWS_PROFILE] --config-version 1
```
