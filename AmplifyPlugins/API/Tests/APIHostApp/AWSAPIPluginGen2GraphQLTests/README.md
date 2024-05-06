## Schema: AWSAPIPluginGen2GraphQLTests

The following steps demonstrate how to set up an GraphQL endpoint with AppSync using Amplify CLI (Gen2). The auth configured will be API Key.

### Set-up

At the time this was written, it follows the steps from here https://docs.amplify.aws/gen2/deploy-and-host/fullstack-branching/mono-and-multi-repos/

1. From a new folder, run `npm create amplify@beta`. This uses the following versions of the Amplify CLI, see `package.json` file below.

```json
{
  ...
  "devDependencies": {
    "@aws-amplify/backend": "^0.15.0",
    "@aws-amplify/backend-cli": "^0.15.0",
    "aws-cdk": "^2.139.0",
    "aws-cdk-lib": "^2.139.0",
    "constructs": "^10.3.0",
    "esbuild": "^0.20.2",
    "tsx": "^4.7.3",
    "typescript": "^5.4.5"
  },
  "dependencies": {
    "aws-amplify": "^6.2.0"
  },
}
```

2. Update `amplify/data/resource.ts` to allow `public` access. This allows using API Key as the auth type to perform CRUD operations against the Comment and Post models. The resulting file should look like this

```ts
const schema = a.schema({
  //# LL.1. Explicit Bi-Directional Belongs-to Has-many PostComment4V2
  //# 11 Explicit Bi-Directional Belongs to Relationship  
  Post4V2: a.model({
    id: a.id().required(), // You can omit this
    title: a.string().required(),
    comments: a.hasMany('Comment4V2', 'postID')
  })
  .authorization(allow => [allow.publicApiKey()]),
  Comment4V2: a.model({
    id: a.id().required(), // You can omit this
    postID: a.id(),
    content: a.string().required(),
    post: a.belongsTo('Post4V2', 'postID')
  })
  .authorization(allow => [allow.publicApiKey()]),

  //# LL.3. Has-Many/Belongs-To With Composite Key
  //# iOS.7. A Has-Many/Belongs-To relationship, each with a composite key
  //# Post with `id` and `title`, Comment with `id` and `content`
  PostWithCompositeKey: a
    .model({
      id: a.id().required(),
      title: a.string().required(),
      comments: a.hasMany("CommentWithCompositeKey", []),
    })
    .identifier(["id", "title"])
    .authorization((allow) => [allow.publicApiKey()]),

  CommentWithCompositeKey: a
    .model({
      id: a.id().required(),
      content: a.string().required(),
      post: a.belongsTo("PostWithCompositeKey", []),
    })
    .identifier(["id", "content"])
    .authorization((allow) => [allow.publicApiKey()]),
});

```

3. Update the API Key expiry to the maximum. This should be done if this backend is used for CI testing.

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
npx amplify sandbox --config-out-dir ./config --profile [PROFILE]
```

5. Copy `amplify_outputs.json` to a new file named `Gen2GraphQLTests-amplify_outputs.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`

```perl
cp amplify_outputs.json ~/.aws-amplify/amplify-ios/testconfiguration/Gen2GraphQLTests-amplify_outputs.json
```

```

6. (Optional) The code generated model files are already checked into the tests so you will only have to re-generate them if you are expecting modifications to them and replace the existing ones checked in.

```
npx amplify generate graphql-client-code --format=modelgen --model-target=swift --out=models --profile lawmicha
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
npx amplify generate outputs --branch main --app-id [APP_ID] --profile [AWS_PROFILE] 
```

8. (Optional) The code generated model files are already checked into the tests so you will only have to re-generate them if you are expecting modifications to them and replace the existing ones checked in.

```
npx amplify generate graphql-client-code --format=modelgen --model-target=swift --branch main --app-id [APP_ID] --profile [AWS_PROFILE]
```
