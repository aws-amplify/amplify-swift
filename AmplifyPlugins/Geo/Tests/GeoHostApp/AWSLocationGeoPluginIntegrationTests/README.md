# Geo Integration Tests

## Schema: AWSLocationGeoPluginIntegrationTests

The following steps demonstrate how to set up Geo. Auth category is also required to allow unauthenticated and authenticated access.

### Set-up

1. `amplify init`

2. `amplify add geo`

```perl
? Select which capability you want to add: `Map (visualize the geospatial data)` 
? geo category resources require auth (Amazon Cognito). Do you want to add auth now? `Yes`
  Do you want to use the default authentication and security configuration? `Default configuration`
  How do you want users to be able to sign in? `Username`
  Do you want to configure advanced settings? `No, I am done.`
? Provide a name for the Map: `<default>`
? Who can access this Map? `Authorized and Guest users`
? Are you tracking commercial assets for your business in your app? `No, I do not track devices or I only need to track consumers' personal devices`
? Do you want to configure advanced settings? `No`
```

3. `amplify add geo`

```perl
? Select which capability you want to add: `Location search (search by places, addresses, coordinates)`
? geo category resources require auth (Amazon Cognito). Do you want to add auth now? `Yes`
? Provide a name for the location search index (place index): `<default>`
? Who can access this search index? `Authorized and Guest users`
? Do you want to configure advanced settings? `No`
```

4. `amplify push`

5. Copy `amplifyconfiguration.json` to a new file named `AWSLocationGeoPluginIntegrationTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`.

6. You can now run all of the integration tests. 

## Schema: AWSLocationGeoPluginGen2IntegrationTests

The following steps demonstrate how to set up Geo and Auth using Amplify CLI Gen2.

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
2. Update `amplify/auth/resource.ts`. The resulting file should look like this

```ts
import { defineAuth, defineFunction } from '@aws-amplify/backend';

/**
 * Define and configure your auth resource
 * @see https://docs.amplify.aws/gen2/build-a-backend/auth
 */
export const auth = defineAuth({
  loginWith: {
    email: true
  },
  triggers: {
    // configure a trigger to point to a function definition
    preSignUp: defineFunction({
      entry: './pre-sign-up-handler.ts'
    })
  }
});

```

```ts
import type { PreSignUpTriggerHandler } from 'aws-lambda';

export const handler: PreSignUpTriggerHandler = async (event) => {
  // your code here
  event.response.autoConfirmUser = true
  return event;
};
```

3. Update `amplify/backend.ts` to create the analytics stack (https://docs.amplify.aws/gen2/build-a-backend/add-aws-services/geo/)

Add the following imports

```ts
import { CfnMap } from "aws-cdk-lib/aws-location";
```

Create `backend` const

```ts
const backend = defineBackend({
  auth,
  // data,
  // storage
  // additional resource
});
```


Add the remaining code

```ts

const geoStack = backend.createStack("geo-stack");

// create a location services map
const map = new CfnMap(geoStack, "Map", {
  mapName: "myMap",
  description: "Map",
  configuration: {
    style: "VectorEsriNavigation",
  },
  pricingPlan: "RequestBasedUsage",
  tags: [
    {
      key: "name",
      value: "myMap",
    },
  ],
});

// create an IAM policy to allow interacting with geo resource
const myGeoPolicy = new Policy(geoStack, "AuthenticatedUserIamRolePolicy", {
  policyName: "GeoPolicy",
  statements: [
    new PolicyStatement({
      actions: [
        "geo:GetMapTile",
        "geo:GetMapSprites",
        "geo:GetMapGlyphs",
        "geo:GetMapStyleDescriptor",
      ],
      resources: [map.attrArn],
    }),
  ],
});

// apply the policy to the authenticated and unauthenticated roles
backend.auth.resources.authenticatedUserIamRole.attachInlinePolicy(myGeoPolicy);
backend.auth.resources.unauthenticatedUserIamRole.attachInlinePolicy(myGeoPolicy);

// patch the custom map resource to the expected output configuration
backend.addOutput({
  geo: {
    aws_region: Stack.of(geoStack).region,
    maps: {
      items: {
        [map.mapName]: {
          style: "VectorEsriNavigation",
        },
      },
      default: map.mapName,
    }
  },
});
```

4. Deploy the backend with npx amplify sandbox

For example, this deploys to a sandbox env and generates the amplify_outputs.json file.

```
npx amplify sandbox --config-out-dir ./config --config-version 1 --profile [PROFILE]
```

5. Copy the `amplify_outputs.json` file over to the test directory as `AWSLocationGeoPluginIntegrationTests-amplify_outputs.json`. The tests will automatically pick this file up. Create the directories in this path first if it currently doesn't exist.

```
cp amplify_outputs.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSLocationGeoPluginIntegrationTests-amplify_outputs.json
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

