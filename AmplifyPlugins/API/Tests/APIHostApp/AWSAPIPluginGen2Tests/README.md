## Schema: AWSAPIPluginGen2FunctionalTests

The following steps demonstrate how to set up an GraphQL endpoint with AppSync using Amplify CLI (Gen2). The auth configured will be API Key.

### Set-up

At the time this was written, it follows the steps from here https://docs.amplify.aws/gen2/deploy-and-host/fullstack-branching/mono-and-multi-repos/

1. From a new folder, run `npm create amplify@beta`. This uses the following versions of the Amplify CLI, see `package.json` file below.

```json
{
  ...
  "devDependencies": {
    "@aws-amplify/backend": "^0.13.0-beta.15",
    "@aws-amplify/backend-cli": "^0.12.0-beta.17",
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
  //# LL.1. Explicit Bi-Directional Belongs-to Has-many PostComment4V2
  //# 11 Explicit Bi-Directional Belongs to Relationship  
  Post4V2: a.model({
    id: a.id().required(), // You can omit this
    title: a.string().required(),
    comments: a.hasMany('Comment4V2', 'postID'),
  })
  .authorization([a.allow.public()]),
  Comment4V2: a.model({
    id: a.id().required(), // You can omit this
    postID: a.id(),
    content: a.string().required(),
    post: a.belongsTo('Post4V2', 'postID')
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

4. Commit and push the files to a git repository.

5. Navigate to the AWS Amplify console (https://us-east-1.console.aws.amazon.com/amplify/home?region=us-east-1#/)

6. Click on "Try Amplify Gen 2" button.

7. Choose "Option 2: Start with an existing app", and choose Github, and press Next.

8. Find the repository and branch, and click Next

9. Click "Save and deploy" and wait for deployment to finish.  

10. Generate the `amplify_outputs.json` configuration file

```
npx amplify generate config --branch [BRANCH] --app-id [APP_ID] --profile [AWS_PROFILE] --config-version 1
```

11. (Optional) The code generated model files are already checked into the tests so you will only have to re-generate them if you are expecting modifications to them and replace the existing ones checked in.

```
npx amplify generate graphql-client-code --format=modelgen --model-target=swift --branch main --app-id [APP_ID] --profile [AWS_PROFILE]
```

12. Copy the `amplify_outputs.json` file over to the test directory as `AWSAPIPluginGen2Tests-amplify_outputs.json`. The tests will automatically pick this file up. Create the directories in this path first if it currently doesn't exist.

```
cp amplify_outputs.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSAPIPluginGen2Tests-amplify_outputs.json
```


## Sandbox testing


Deploy sandbox
```
npx amplify sandbox --profile [PROFILE]
```

Generate code 
```
npx amplify generate graphql-client-code --format=modelgen --model-target=swift --out=models --profile [PROFILE]
```
