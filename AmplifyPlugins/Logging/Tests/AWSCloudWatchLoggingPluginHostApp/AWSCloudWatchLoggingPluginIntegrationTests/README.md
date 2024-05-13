# AWS CloudWatch Logging Integration Tests

## Schema: AWSCloudWatchLoggingPluginIntegrationTests

The following steps demonstrate how to set up Logging. Auth category is also required to allow unauthenticated and authenticated access.

### Set-up

1. Configure app with Auth category using Amplify CLI

2. Copy `amplifyconfiguration.json` to a new file named `AWSCloudWatchLoggingPluginIntegrationTests-amplifyconfiguration.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`.

```
cp amplifyconfiguration.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSCloudWatchLoggingPluginIntegrationTests-amplifyconfiguration.json
```

3. Configure the `amplifyconfiguration-logging.json` file (https://docs.amplify.aws/swift/build-a-backend/more-features/logging/set-up-logging/#initialize-amplify-logging)

```json
{
    "awsCloudWatchLoggingPlugin": {
        "enable": true,
        "logGroupName": "<log-group-name>",
        "region": "<region>",
        "localStoreMaxSizeInMB": 1,
        "flushIntervalInSeconds": 60,
        "loggingConstraints": {
            "defaultLogLevel": "VERBOSE"
        }
    }
}
```
4. Copy `amplifyconfiguration_logging.json` to a new file named `AWSCloudWatchLoggingPluginIntegrationTests-amplifyconfiguration_logging.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`.

```
cp amplifyconfiguration_logging.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSCloudWatchLoggingPluginIntegrationTests-amplifyconfiguration_logging.json
```

5. You can now run all of the integration tests. 

## Schema: AWSCloudWatchLoggingPluginGen2IntegrationTests

The following steps demonstrate how to set up Logging. Auth category is also required to allow unauthenticated and authenticated access.

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
  }
});

```

3. Create `amplify/custom/RemoteLoggingConstraintsConstruct.resource.ts` and add the following

```ts
import * as cdk from "aws-cdk-lib"
import { Construct } from "constructs"
import * as logs from "aws-cdk-lib/aws-logs"
import * as iam from "aws-cdk-lib/aws-iam"

export class RemoteLoggingConstraintsConstruct extends Construct {
  constructor(scope: Construct, id: string, authRoleName: string, unAuthRoleName: string) {
    super(scope, id)

    const region = cdk.Stack.of(this).region
    const account = cdk.Stack.of(this).account
    const logGroupName = "<log-group-name>"
    
    new logs.LogGroup(this, 'Log Group', {
      logGroupName: logGroupName,
      retention: logs.RetentionDays.INFINITE
    })

    const authRole = iam.Role.fromRoleName(this, "Auth-Role", authRoleName)
    const unAuthRole = iam.Role.fromRoleName(this, "UnAuth-Role", unAuthRoleName)
    const logResource = `arn:aws:logs:${region}:${account}:log-group:${logGroupName}:log-stream:*`
    const logIAMPolicy = new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      resources: [logResource],
      actions: ["logs:PutLogEvents", "logs:DescribeLogStreams", "logs:CreateLogStream", "logs:FilterLogEvents"]
    })

    authRole.addToPrincipalPolicy(logIAMPolicy)
    unAuthRole.addToPrincipalPolicy(logIAMPolicy)

    new cdk.CfnOutput(this, 'CloudWatchLogGroupName', { value: logGroupName });
    new cdk.CfnOutput(this, 'CloudWatchRegion', { value: region });
  }
}
```

Update `backend.ts`.

```ts
import { defineBackend } from '@aws-amplify/backend';
import { auth } from './auth/resource';
import { RemoteLoggingConstraintsConstruct } from './custom/RemoteLoggingConstraintsConstruct/resource';

const backend = defineBackend({
  auth
});

// Auth - sign in with username
const { cfnUserPool } = backend.auth.resources.cfnResources
cfnUserPool.usernameAttributes = []

// ============ Logging Stack ===========

const loggingConstruct = new RemoteLoggingConstraintsConstruct(
  backend.createStack('logging-stack'),
  'logging-stack',
  backend.auth.resources.authenticatedUserIamRole.roleName,
  backend.auth.resources.unauthenticatedUserIamRole.roleName
);

```

4. Deploy the backend with npx amplify sandbox

For example, this deploys to a sandbox env and generates the amplify_outputs.json file.

```
npx amplify sandbox --config-out-dir ./config --profile [PROFILE]
```

5. Copy `amplify_outputs.json` to a new file named `AWSCloudWatchLoggingPluginIntegrationTests-amplify_outputs.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`.

```
cp amplify_outputs.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSCloudWatchLoggingPluginIntegrationTests-amplify_outputs.json
```

6. Configure the `amplifyconfiguration_logging_gen2.json` file (https://docs.amplify.aws/swift/build-a-backend/add-aws-services/logging/set-up-logging/#initialize-amplify-logging)

```json
{
    "awsCloudWatchLoggingPlugin": {
        "enable": true,
        "logGroupName": "<log-group-name>",
        "region": "<region>",
        "localStoreMaxSizeInMB": 1,
        "flushIntervalInSeconds": 60,
        "loggingConstraints": {
            "defaultLogLevel": "VERBOSE"
        }
    }
}
```

7. Copy `amplifyconfiguration_logging_gen2.json` to a new file named `AWSCloudWatchLoggingPluginIntegrationTests-amplifyconfiguration_logging_gen2.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`.

```
cp amplifyconfiguration_logging_gen2.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSCloudWatchLoggingPluginIntegrationTests-amplifyconfiguration_logging_gen2.json
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
