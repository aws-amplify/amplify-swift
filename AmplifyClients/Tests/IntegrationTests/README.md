# Kinesis & Firehose E2E Integration Tests

Tests for `AmplifyKinesisClient` and `AmplifyFirehoseClient` running against real Kinesis Data Streams and Firehose Delivery Streams with pre-provisioned Cognito credentials.

## Part 1: Deploy the Backend

The infra folder is gitignored. Create it from scratch inside `KinesisFirehoseClientHostApp/`:

```bash
cd KinesisFirehoseClientHostApp
npm create amplify@latest -- --yes -p infra
cd infra
```

Replace `amplify/auth/resource.ts`:

```ts
import { defineAuth } from '@aws-amplify/backend';

export const auth = defineAuth({
  loginWith: {
    email: true,
  },
});
```

Replace `amplify/backend.ts`:

```ts
import { defineBackend } from '@aws-amplify/backend';
import { auth } from './auth/resource';
import * as kinesis from 'aws-cdk-lib/aws-kinesis';
import * as firehose from 'aws-cdk-lib/aws-kinesisfirehose';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Duration, RemovalPolicy } from 'aws-cdk-lib';
import { PolicyStatement } from 'aws-cdk-lib/aws-iam';

const backend = defineBackend({
  auth,
});

// Kinesis Data Stream
const kinesisStack = backend.createStack('KinesisStack');

const stream = new kinesis.Stream(kinesisStack, 'TestStream', {
  streamName: 'amplify-kinesis-swift-test-stream',
  shardCount: 1,
  retentionPeriod: Duration.hours(24),
});

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

// Firehose Delivery Stream
const firehoseStack = backend.createStack('FirehoseStack');

const firehoseBucket = new s3.Bucket(firehoseStack, 'FirehoseDestinationBucket', {
  removalPolicy: RemovalPolicy.DESTROY,
  autoDeleteObjects: true,
});

const firehoseRole = new iam.Role(firehoseStack, 'FirehoseDeliveryRole', {
  assumedBy: new iam.ServicePrincipal('firehose.amazonaws.com'),
});

firehoseBucket.grantReadWrite(firehoseRole);

const deliveryStream = new firehose.CfnDeliveryStream(
  firehoseStack,
  'TestDeliveryStream',
  {
    deliveryStreamName: 'amplify-firehose-swift-test-stream',
    s3DestinationConfiguration: {
      bucketArn: firehoseBucket.bucketArn,
      roleArn: firehoseRole.roleArn,
      bufferingHints: {
        intervalInSeconds: 60,
        sizeInMBs: 1,
      },
    },
  }
);

backend.auth.resources.authenticatedUserIamRole.addToPrincipalPolicy(
  new PolicyStatement({
    actions: [
      'firehose:PutRecord',
      'firehose:PutRecordBatch',
      'firehose:DescribeDeliveryStream',
    ],
    resources: [
      `arn:aws:firehose:*:*:deliverystream/${deliveryStream.deliveryStreamName}`,
    ],
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
- Firehose Delivery Stream (`amplify-firehose-swift-test-stream`) with an S3 destination
- IAM policies granting authenticated users access to both streams

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
  ~/.aws-amplify/amplify-ios/testconfiguration/AmplifyKinesisClientIntegrationTests-amplify_outputs.json
```

Create the credentials file:
```bash
cat > ~/.aws-amplify/amplify-ios/testconfiguration/AmplifyKinesisClientIntegrationTests-credentials.json << 'EOF'
{
  "username": "[EMAIL]",
  "password": "[PASSWORD]"
}
EOF
```
