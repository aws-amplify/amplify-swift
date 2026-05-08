# CloudWatch Logging Client Integration Tests

## Set-up

1. From a new folder, run `npm create amplify@latest`. 

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

3. Create `amplify/custom/LoggingConstruct/resource.ts` and add the following.

```ts
import * as cdk from "aws-cdk-lib"
import { Construct } from "constructs"
import * as logs from "aws-cdk-lib/aws-logs"
import * as iam from "aws-cdk-lib/aws-iam"

export class LoggingConstruct extends Construct {
  constructor(scope: Construct, id: string, authRoleName: string, unAuthRoleName: string) {
    super(scope, id)

    const region = cdk.Stack.of(this).region
    const account = cdk.Stack.of(this).account
    const logGroupName = "cloudwatch-integration-test-log-group"
    
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
import { LoggingConstruct } from './custom/LoggingConstruct/resource';

const backend = defineBackend({
  auth
});

// Auth - sign in with username
const { cfnUserPool } = backend.auth.resources.cfnResources
cfnUserPool.usernameAttributes = []

// ============ Logging Stack ===========

const loggingConstruct = new LoggingConstruct(
  backend.createStack('logging-stack'),
  'logging-stack',
  backend.auth.resources.authenticatedUserIamRole.roleName,
  backend.auth.resources.unauthenticatedUserIamRole.roleName
);
```

4. Deploy the backend with `npx ampx sandbox`. This will generate the `amplify_outputs.json` file.

5. Copy `amplify_outputs.json` to a new file named `CloudWatchLoggingClientIntegrationTests-amplify_outputs.json` inside `~/.aws-amplify/amplify-ios/testconfiguration/`.

```
cp amplify_outputs.json ~/.aws-amplify/amplify-ios/testconfiguration/CloudWatchLoggingClientIntegrationTests-amplify_outputs.json
```

6. Create a `CloudWatchLoggingClientIntegrationTests-configuration.json` with following - Update the `region` in which the backend is deployed.

```json
{
    "cloudWatchClient": {
        "enable": true,
        "logGroupName": "cloudwatch-integration-test-log-group",
        "region": "<your-region>",
        "localStoreMaxSizeInMB": 1,
        "flushIntervalInSeconds": 60,
        "loggingConstraints": {
            "defaultLogLevel": "VERBOSE"
        }
    }
}
```

7. Move `CloudWatchLoggingClientIntegrationTests-configuration.json`  inside `~/.aws-amplify/amplify-ios/testconfiguration/`
