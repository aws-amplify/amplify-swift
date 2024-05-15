## Schema: AWSAPIPluginGen2GraphQLTests

The following steps demonstrate how to set up an GraphQL endpoint with AppSync using Amplify CLI (Gen2). The auth configured will be API Key.

### Set-up

At the time this was written, it follows the steps from here https://docs.amplify.aws/gen2/deploy-and-host/fullstack-branching/mono-and-multi-repos/

1. From a new folder, run `npm create amplify@beta`. This uses the following versions of the Amplify CLI, see `package.json` file below.

```json
{
  ...
  "devDependencies": {
    "@aws-amplify/backend": "^1.0.1",
    "@aws-amplify/backend-cli": "^1.0.1",
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
    
    // Gen2_1
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/add-fields/#specify-a-custom-field-type
    Location1: a.customType({
      lat: a.float(),
      long: a.float(),
    }),
    Post1: a.model({
      location: a.ref('Location1'),
      content: a.string(),
    }),
    User1: a.model({
      lastKnownLocation: a.ref('Location1'),
    }),

    // Gen2_2
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/add-fields/#specify-an-enum-field-type
    PrivacySetting2: a.enum([
      'PRIVATE',
      'FRIENDS_ONLY',
      'PUBLIC'
    ]),
    Post2: a.model({
      content: a.string(),
      privacySetting: a.ref('PrivacySetting2'),
    }),
    Video2: a.model({
      privacySetting: a.ref('PrivacySetting2'),
    }),

    // Gen2_3
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/relationships/#model-one-to-many-relationships
    Member3: a.model({
        name: a.string().required(),
        // 1. Create a reference field
        teamId: a.id(),
        // 2. Create a belongsTo relationship with the reference field
        team: a.belongsTo('Team3', 'teamId'),
    })
    .authorization(allow => [allow.publicApiKey()]),

    Team3: a.model({
        mantra: a.string().required(),
        // 3. Create a hasMany relationship with the reference field
        //    from the `Member`s model.
        members: a.hasMany('Member3', 'teamId'),
    })
    .authorization(allow => [allow.publicApiKey()]),

    // Gen2_4 - Model a "one-to-one" relationship
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/relationships/#model-a-one-to-one-relationship
    Cart4: a.model({
        items: a.string().required().array(),
        // 1. Create reference field
        customerId: a.id(),
        // 2. Create relationship field with the reference field
        customer: a.belongsTo('Customer4', 'customerId'),
    }),
    Customer4: a.model({
        name: a.string(),
        // 3. Create relationship field with the reference field
        //    from the Cart model
        activeCart: a.hasOne('Cart4', 'customerId')
    }),
    
    // Gen2_41 -Model multiple relationships between two models
    // http://localhost:3000/swift/build-a-backend/data/data-modeling/relationships/#model-multiple-relationships-between-two-models
    Post41: a.model({
      title: a.string().required(),
      content: a.string().required(),

      authorId: a.id(),
      author: a.belongsTo('Person41', 'authorId'),
      editorId: a.id(),
      editor: a.belongsTo('Person41', 'editorId'),
    }),
    Person41: a.model({
      name: a.string(),
      editedPosts: a.hasMany('Post41', 'editorId'),
      authoredPosts: a.hasMany('Post41', 'authorId'),
    }),
  
    // Gen2_5 - Customize data model identifiers
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/identifiers/
    Todo5: a.model({
        content: a.string(),
        completed: a.boolean(),
    }),
    
    // Gen2_6 - Single-field identifier
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/identifiers/#single-field-identifier
    Todo6: a.model({
        todoId: a.id().required(),
        content: a.string(),
        completed: a.boolean(),
    })
    .identifier(['todoId']),
    
    // Gen2_7 - Composite identifier
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/identifiers/#composite-identifier
    StoreBranch7: a.model({
        tenantId: a.id().required(),
        name: a.string().required(),
        country: a.string(),
        state: a.string(),
        city: a.string(),
        zipCode: a.string(),
        streetAddress: a.string(),
    })
    .identifier(['tenantId', 'name']),
    
    // Gen2_8 - Customize secondary indexes
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/secondary-index/
    Customer8: a
      .model({
        name: a.string(),
        phoneNumber: a.phone(),
        accountRepresentativeId: a.id().required(),
    })
    .secondaryIndexes((index) => [index("accountRepresentativeId")]),
    
    // Gen2_9
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/secondary-index/#add-sort-keys-to-secondary-indexes
    Customer9: a
      .model({
        name: a.string(),
        phoneNumber: a.phone(),
        accountRepresentativeId: a.id().required(),
    })
    .secondaryIndexes((index) => [
       index("accountRepresentativeId")
        .sortKeys(["name"]),
    ]),
    
    // Gen2_10
    // https://docs.amplify.aws/swift/build-a-backend/data/data-modeling/secondary-index/#customize-the-query-field-for-secondary-indexes
    Customer10: a
      .model({
        name: a.string(),
        phoneNumber: a.phone(),
        accountRepresentativeId: a.id().required(),
    })
    .secondaryIndexes((index) => [
      index("accountRepresentativeId")
        .queryField("listByRep"),
    ]),
    
}).authorization(allow => [allow.publicApiKey()]);

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
npx ampx generate graphql-client-code --format=modelgen --model-target=swift --profile [PROFILE] --out=models
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
