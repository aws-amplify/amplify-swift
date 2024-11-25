# Schema: AuthIntegrationTests - AWSCognitoAuthPlugin Integration tests

The following steps demonstrate how to setup the integration tests for auth plugin where an OTP is sent to the user's email address or phone number. T

## Schema: AuthGen2IntegrationTests

The following steps demonstrate how to setup the integration tests for auth plugin using Amplify CLI (Gen2).

### Set-up

At the time this was written, it follows the steps from here https://docs.amplify.aws/gen2/deploy-and-host/fullstack-branching/mono-and-multi-repos/

1. From a new folder, run `npm create amplify@latest`. This will create a new amplify project with the latest version of the Amplify CLI.

2. Update `amplify/auth/resource.ts`. The resulting file should look like this. Replace `<your_verified_email>` with your verified email address.

```ts
import { defineAuth } from '@aws-amplify/backend';

const fromEmail = '<your_verified_email>';

/**
 * Define and configure your auth resource
 * @see https://docs.amplify.aws/gen2/build-a-backend/auth
 */
export const auth = defineAuth({
  loginWith: {
    email: true,
  },
  multifactor: {
    mode: "REQUIRED",
    sms: true,
  },
  userAttributes: {
    email: {
      required: false,
      mutable: true,
    },
    phoneNumber: {
      required: false,
      mutable: true,
    },
  },
  accountRecovery: "NONE",
  senders: {
    email: {
      fromEmail,
    },
  },
  triggers: {
    // configure a trigger to point to a function definition
    preSignUp: defineFunction({
      entry: "./pre-sign-up-handler.ts",
    }),
  },
});
```

3. Create a file `amplify/functions/cognito-triggers/pre-sign-up-handler.ts` with the following content

```ts
import type { PreSignUpTriggerHandler } from "aws-lambda";

export const handler: PreSignUpTriggerHandler = async (event) => {
  event.response.autoConfirmUser = true; // Automatically confirm the user

  // Automatically mark the user's email as verified
  if (event.request.userAttributes.hasOwnProperty("email")) {
    event.response.autoVerifyEmail = true; // Automatically verify the email
  }

  // Automatically mark the user's phone number as verified
  if (event.request.userAttributes.hasOwnProperty("phone_number")) {
    event.response.autoVerifyPhone = true; // Automatically verify the phone number
  }
  // Return to Amazon Cognito
  return event;
};
```

4. Create a file `amplify/data/mfa/index.graphql` with the following content

```graphql
# A Graphql Schema for creating Mfa info such as code and username.

type Query {
	listMfaInfo: [MfaInfo] @aws_api_key
}

type Mutation {
	createMfaInfo(input: CreateMfaInfoInput!): MfaInfo @aws_api_key
}

type Subscription {
	onCreateMfaInfo(username: String): MfaInfo
		@aws_subscribe(mutations: ["createMfaInfo"])
}

input CreateMfaInfoInput {
	username: String!
	code: String!
	expirationTime: AWSTimestamp!
}

type MfaInfo {
	username: String!
	code: String!
	expirationTime: AWSTimestamp!
}
```

5. Update `amplify/data/mfa/index.ts`. The resulting file should look like this

```ts
import { Duration, Expiration, RemovalPolicy, Stack } from "aws-cdk-lib";
import {
  Assign,
  AuthorizationType,
  FieldLogLevel,
  GraphqlApi,
  MappingTemplate,
  PrimaryKey,
  SchemaFile,
  Values,
} from "aws-cdk-lib/aws-appsync";
import { Table, BillingMode, AttributeType } from "aws-cdk-lib/aws-dynamodb";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * It creates AppSync and Dynamo resources using CDK
 *
 * *Note: It was not possible to use gen2 to create data resources due to a circular dependency error while
 * deploying resources.*
 *
 * A circular dependency is when,
 *
 * - a resource that is being deployed depends on another resource that is being deployed and vice-versa.
 * - or a resource depends on its own resource.
 *
 * For instance,
 *
 * Auth resources -> Data resources -> Auth resources
 *
 * Reference: https://aws.amazon.com/blogs/infrastructure-and-automation/handling-circular-dependency-errors-in-aws-cloudformation/
 *
 */
export function createMfaInfoGraphqlApi(stack: Stack): GraphqlApi {
  const authorizationType = AuthorizationType.API_KEY;
  const resolvedPath = path.resolve(__dirname, "index.graphql");
  const graphqlapi = new GraphqlApi(stack, "MfaInfoGraphqlApi", {
    name: "MfaInfoGraphql",
    definition: {
      schema: SchemaFile.fromAsset(resolvedPath),
    },
    authorizationConfig: {
      defaultAuthorization: {
        authorizationType,
        apiKeyConfig: {
          expires: Expiration.after(Duration.days(365)),
        },
      },
    },
    logConfig: {
      fieldLogLevel: FieldLogLevel.ALL,
      excludeVerboseContent: false,
    },
  });

  const mfaCodesTable = new Table(stack, `MfaInfoTable`, {
    removalPolicy: RemovalPolicy.DESTROY,
    billingMode: BillingMode.PAY_PER_REQUEST,
    partitionKey: {
      type: AttributeType.STRING,
      name: "username",
    },
    sortKey: {
      type: AttributeType.STRING,
      name: "code",
    },
    timeToLiveAttribute: "expirationTime",
  });

  const mfaCodesSource = graphqlapi.addDynamoDbDataSource(
    "GraphQLApiMFACodes",
    mfaCodesTable
  );
  // Mutation.createMfaInfo
  mfaCodesSource.createResolver(`MutationCreateMFACodeResolver`, {
    typeName: "Mutation",
    fieldName: "createMfaInfo",
    requestMappingTemplate: MappingTemplate.dynamoDbPutItem(
      new PrimaryKey(
        new Assign("username", "$input.username"),
        new Assign("code", "$input.code")
      ),
      Values.projecting("input")
    ),
    responseMappingTemplate: MappingTemplate.dynamoDbResultItem(),
  });

  // Query.listMFACodes
  mfaCodesSource.createResolver(`QueryListMfaInfoResolver`, {
    typeName: "Query",
    fieldName: "listMfaInfo",
    requestMappingTemplate: MappingTemplate.dynamoDbScanTable(),
    responseMappingTemplate: MappingTemplate.dynamoDbResultItem(),
  });

  return graphqlapi;
}
```

Update `backend.ts`

```ts
import { defineBackend } from "@aws-amplify/backend";
import { auth } from "./auth/resource";
import { Key } from "aws-cdk-lib/aws-kms";
import { RemovalPolicy } from "aws-cdk-lib";
import { createMfaInfoGraphqlApi } from "./data/mfaInfo";
import { senderFactory } from "./helpers";

enum LambdaEnvKeys {
  GRAPHQL_API_ENDPOINT = "GRAPHQL_API_ENDPOINT",
  GRAPHQL_API_KEY = "GRAPHQL_API_KEY",
  KMS_KEY_ARN = "KMS_KEY_ARN",
}

const backend = defineBackend({
  auth,
});

const { cfnResources, userPool } = backend.auth.resources;
const { stack } = userPool;
const { cfnUserPool } = cfnResources;

// an empty array denotes "email" and "phone_number" cannot be used as a username
cfnUserPool.usernameAttributes = [];

// Create data resources
const mfaInfoGraphqlApi = createMfaInfoGraphqlApi(userPool.stack);
// Create kms resources
const customSenderKmsKey = new Key(stack, "CustomSenderKmsKey", {
  description: `Key for encrypting/decrypting messages`,
  removalPolicy: RemovalPolicy.DESTROY,
});
// Create Cognito senders
const environment = {
  [LambdaEnvKeys.GRAPHQL_API_ENDPOINT]: mfaInfoGraphqlApi.graphqlUrl,
  [LambdaEnvKeys.GRAPHQL_API_KEY]: mfaInfoGraphqlApi.apiKey ?? "",
  [LambdaEnvKeys.KMS_KEY_ARN]: customSenderKmsKey.keyArn,
};
const cognitoSender = senderFactory(
  stack,
  mfaInfoGraphqlApi,
  customSenderKmsKey,
  cfnUserPool
);
const customEmailSender = cognitoSender("email-sender", environment);
const customSmsSender = cognitoSender("sms-sender", environment);

// Configure the user pool to use the custom senders
cfnUserPool.lambdaConfig = {
  customEmailSender: {
    lambdaArn: customEmailSender.functionArn,
    lambdaVersion: "V1_0",
  },
  customSmsSender: {
    lambdaArn: customSmsSender.functionArn,
    lambdaVersion: "V1_0",
  },
  kmsKeyId: customSenderKmsKey.keyArn,
};

// Add data resources output.
// Gen2 won't be able to auto generate data output as data resources were generated by CDK.
backend.addOutput({
  data: {
    aws_region: stack.region,
    url: mfaInfoGraphqlApi.graphqlUrl,
    api_key: mfaInfoGraphqlApi.apiKey,
    default_authorization_type: "API_KEY",
    authorization_types: [],
  },
});

// Enable Device Tracking
// https://docs.amplify.aws/react/build-a-backend/auth/concepts/multi-factor-authentication/#remember-a-device

cfnUserPool.addPropertyOverride("DeviceConfiguration", {
  ChallengeRequiredOnNewDevice: true,
  DeviceOnlyRememberedOnUserPrompt: false,
});
```

6. Create a file `amplify/functions/cognito-triggers/common.ts` with the following content

```ts
// Code adapted from:
// - https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-lambda-custom-sms-sender.html#code-examples
// - https://github.com/aws-samples/amazon-cognito-user-pool-development-and-testing-with-sms-redirected-to-email

import {
  buildClient,
  CommitmentPolicy,
  KmsKeyringNode,
} from "@aws-crypto/client-node";

const { decrypt } = buildClient(CommitmentPolicy.FORBID_ENCRYPT_ALLOW_DECRYPT);

/**
 * Decrypts `code` using the KMS keyring provided by the environment.
 * @param code The encrypted code sent from Cognito.
 * @returns The plaintext (decrypted) code.
 */
const decryptCode = async (code: string): Promise<string> => {
  const { KMS_KEY_ARN } = process.env;
  const keyring = new KmsKeyringNode({
    keyIds: [KMS_KEY_ARN!],
  });
  const { plaintext } = await decrypt(keyring, Buffer.from(code, "base64"));
  return plaintext.toString("ascii");
};

/**
 * Decrypts and broadcasts `code` to the AppSync endpoint provided by the environment.
 * @param code The encrypted code sent from Cognito.
 */
export const decryptAndBroadcastCode = async (
  username: string,
  code: string
): Promise<void> => {
  const { GRAPHQL_API_ENDPOINT, GRAPHQL_API_KEY } = process.env;
  const plaintextCode = await decryptCode(code);
  console.log(`Got MFA code for username ${username}: ${plaintextCode}`);
  const EXPIRATION_TIME_IN_SECONDS = 1 * 60 * 1000; // 1 minute;
  try {
    const resp = await fetch(GRAPHQL_API_ENDPOINT!, {
      method: "POST",
      headers: {
        "x-api-key": GRAPHQL_API_KEY!,
      },
      body: JSON.stringify({
        query: `
                  mutation CreateMfaInfo($username: String!, $code: String! $expirationTime: AWSTimestamp!) {
                      createMfaInfo(input: {
                          username: $username
                          code: $code
                          expirationTime: $expirationTime 
                      }) {
                          username
                          code
                          expirationTime
                      }
                  }
              `,
        variables: {
          username,
          code: plaintextCode,
          expirationTime:
            Math.floor(Date.now() / 1000) + EXPIRATION_TIME_IN_SECONDS,
        },
      }),
    });
    const json = await resp.json();
    console.log(`Got GraphQL response: ${JSON.stringify(json, null, 2)}`);
  } catch (error) {
    console.error("Could not POST to GraphQL endpoint: ", error);
  }
};
```

7. Create a file `amplify/functions/cognito-triggers/custom-email-sender.ts` with the following content

```ts
import { CustomEmailSenderTriggerHandler } from "aws-lambda";
import { decryptAndBroadcastCode } from "./common";

export const handler: CustomEmailSenderTriggerHandler = async (event) => {
  console.log(`Got event: ${JSON.stringify(event, null, 2)}`);

  if (
    event.triggerSource === "CustomEmailSender_AdminCreateUser" ||
    event.triggerSource == "CustomEmailSender_AccountTakeOverNotification"
  ) {
    console.warn(`Not handling trigger source: ${event.triggerSource}`);
    return event;
  }

  const { userName } = event;
  const { code } = event.request;

  await decryptAndBroadcastCode(userName, code!);

  return event;
};
```

8. Create a file `amplify/functions/cognito-triggers/custom-sms-sender.ts` with the following content


```ts
import { CustomSMSSenderTriggerHandler } from "aws-lambda";
import { decryptAndBroadcastCode } from "./common";

export const handler: CustomSMSSenderTriggerHandler = async (event) => {
  console.log(`Got event: ${JSON.stringify(event, null, 2)}`);

  if (event.triggerSource === "CustomSMSSender_AdminCreateUser") {
    console.warn(`Not handling trigger source: ${event.triggerSource}`);
    return event;
  }

  const { userName } = event;
  const { code } = event.request;

  await decryptAndBroadcastCode(userName, code!);

  return event;
};
```

9. Deploy the backend with npx amplify sandbox

For example, this deploys to a sandbox env and generates the amplify_outputs.json file.

```
npx ampx sandbox --identifier mfa-req-email  --outputs-out-dir amplify_outputs/mfa-req-email
```

10. Copy the `amplify_outputs.json` file over to the test directory as `XYZ-amplify_outputs.json` (replace xyz with the name of the file your test is expecting). The tests will automatically pick this file up. Create the directories in this path first if it currently doesn't exist.

```
cp amplify_outputs.json ~/.aws-amplify/amplify-ios/testconfiguration/XYZ-amplify_outputs.json
```