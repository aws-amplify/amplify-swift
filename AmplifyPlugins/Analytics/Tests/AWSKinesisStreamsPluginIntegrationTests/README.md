# Kinesis Streams E2E Integration Tests

Tests for `AmplifyKinesisClient` running against a real Kinesis Data Stream with pre-provisioned Cognito credentials.

## Part 1: Deploy the Backend

From a new folder, run `npm create amplify@latest`. This uses the following versions of the Amplify CLI, see `package.json` file below.

```json
{
  "name": "kinesis-e2e-test-infra",
  "version": "1.0.0",
  "type": "module",
  "devDependencies": {
    "@aws-amplify/backend": "^1.21.0",
    "@aws-amplify/backend-cli": "^1.8.2",
    "aws-cdk-lib": "^2.234.1",
    "constructs": "^10.5.1",
    "esbuild": "^0.27.3",
    "tsx": "^4.21.0",
    "typescript": "^5.9.3"
  },
  "dependencies": {
    "aws-amplify": "^6.16.2"
  }
}
```

Update `amplify/auth/resource.ts`:

```ts
import { defineAuth } from '@aws-amplify/backend';

export const auth = defineAuth({
  loginWith: {
    email: true,
  },
});
```

Update `amplify/backend.ts` to create the Kinesis stream and grant permissions to authenticated users:

```ts
import { defineBackend } from '@aws-amplify/backend';
import { auth } from './auth/resource';
import * as kinesis from 'aws-cdk-lib/aws-kinesis';
import { Duration } from 'aws-cdk-lib';
import { PolicyStatement } from 'aws-cdk-lib/aws-iam';

const backend = defineBackend({
  auth,
});

const kinesisStack = backend.createStack('KinesisStack');

const stream = new kinesis.Stream(kinesisStack, 'TestStream', {
  streamName: 'amplify-kinesis-swift-test-stream',
  shardCount: 1,
  retentionPeriod: Duration.hours(24),
});

// Only authenticated users get Kinesis permissions
backend.auth.resources.authenticatedUserIamRole.addToPrincipalPolicy(
  new PolicyStatement({
    actions: [
      'kinesis:PutRecord',
      'kinesis:PutRecords',
      'kinesis:DescribeStream',
    ],
    resources: [stream.streamArn],
  })
);
```

Deploy with Amplify sandbox:

```bash
npx ampx sandbox --profile [YOUR_AWS_PROFILE]
```

This creates:
- Cognito User Pool + Identity Pool
- Kinesis Data Stream (`amplify-kinesis-swift-test-stream`, 1 shard, 24h retention)
- IAM policy granting `kinesis:PutRecord`, `kinesis:PutRecords`, `kinesis:DescribeStream` to the authenticated role

## Part 2: Create a Test User

After the backend is deployed, create a user in the Cognito User Pool:

```bash
# Get the User Pool ID from amplify_outputs.json
USER_POOL_ID=$(cat amplify_outputs.json | python3 -c "import sys,json; print(json.load(sys.stdin)['auth']['user_pool_id'])")

# Create the user
aws cognito-idp admin-create-user \
  --user-pool-id $USER_POOL_ID \
  --username [EMAIL] \
  --temporary-password '[TEMP_PASSWORD]' \
  --user-attributes Name=email,Value=[EMAIL] Name=email_verified,Value=true \
  --message-action SUPPRESS \
  --profile [YOUR_AWS_PROFILE]

# Set a permanent password
aws cognito-idp admin-set-user-password \
  --user-pool-id $USER_POOL_ID \
  --username [EMAIL] \
  --password '[PASSWORD]' \
  --permanent \
  --profile [YOUR_AWS_PROFILE]
```

## Part 3: Copy Configuration Files

```bash
mkdir -p ~/.aws-amplify/amplify-ios/testconfiguration
```

Copy the Amplify outputs:
```bash
cp amplify_outputs.json \
  ~/.aws-amplify/amplify-ios/testconfiguration/AWSKinesisStreamsPluginIntegrationTests-amplify_outputs.json
```

Create the credentials file:
```bash
cat > ~/.aws-amplify/amplify-ios/testconfiguration/AWSKinesisStreamsPluginIntegrationTests-credentials.json << 'EOF'
{
  "username": "[EMAIL]",
  "password": "[PASSWORD]"
}
EOF
```
