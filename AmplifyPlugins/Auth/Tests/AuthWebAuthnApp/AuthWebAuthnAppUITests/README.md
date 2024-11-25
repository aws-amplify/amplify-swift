# Schema: AuthIntegrationTests - AWSCognitoAuthPlugin Integration tests

The following steps demonstrate how to setup the integration tests for auth plugin where an OTP is sent to the user's email address or phone number. T

## Schema: AuthGen2IntegrationTests

The following steps demonstrate how to setup the integration tests for auth plugin using Amplify CLI (Gen2).

### Set-up

At the time this was written, it follows the steps from here https://docs.amplify.aws/gen2/deploy-and-host/fullstack-branching/mono-and-multi-repos/

1. From a new folder, run `npm create amplify@latest`. This will create a new amplify project with the latest version of the Amplify CLI.

2. Update `amplify/auth/resource.ts`. The resulting file should look like this. Replace `<your_verified_email>` with your verified email address.

```ts
import { defineAuth, defineFunction } from '@aws-amplify/backend';

const fromEmail = '<your_verified_email>>';

function getAuthDefinition(): Parameters<typeof defineAuth>[0] {
	return {
		loginWith: {
			email: true,
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
		accountRecovery: 'NONE',
		multifactor: {
			mode: 'OPTIONAL',
			totp: true,
			sms: true,
		},
		senders: {
			email: {
				fromEmail,
			},
		},
		triggers: {
		  preSignUp: defineFunction({
			  entry: "./pre-sign-up-handler.ts",
		  }),
		},
	};
}

export const auth = defineAuth(getAuthDefinition());

```

3. Create a file `amplify/auth/pre-sign-up-handler.ts` with the following content
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

4. Update `backend.ts` with the following content and replace the `WebAuthnRelyingPartyID` with your own relying party ID.

```ts
import { defineBackend } from '@aws-amplify/backend';
import { auth } from './auth/resource';

const backend = defineBackend({
	auth,
});

const { cfnResources } = backend.auth.resources;
const { cfnUserPool, cfnUserPoolClient } = cfnResources;

cfnUserPool.addPropertyOverride(
	'Policies.SignInPolicy.AllowedFirstAuthFactors',
	['PASSWORD', 'WEB_AUTHN', 'EMAIL_OTP', 'SMS_OTP']
);

// sign in with username
cfnUserPool.usernameAttributes = [];

cfnUserPoolClient.explicitAuthFlows = [
	'ALLOW_REFRESH_TOKEN_AUTH',
	'ALLOW_USER_AUTH',
	'ALLOW_USER_PASSWORD_AUTH',
	'ALLOW_USER_SRP_AUTH',
];

cfnUserPool.addPropertyOverride('WebAuthnRelyingPartyID', '<YOUR_RELYING_PARTY>');
cfnUserPool.addPropertyOverride('WebAuthnUserVerification', 'preferred');
```

4. Deploy the backend with npx amplify sandbox

For example, this deploys to a sandbox env and generates the amplify_outputs.json file.

```
npx ampx sandbox --identifier webauthn-tests  --outputs-out-dir amplify_outputs/webauthn-tests
```

5. Copy the `amplify_outputs.json` file over to the test directory as `AWSCognitoPluginWebAuthnIntegrationTests-amplify_outputs.json`. The tests will automatically pick this file up. Create the directories in this path first if it currently doesn't exist.

```
cp amplify_outputs.json ~/.aws-amplify/amplify-ios/testconfiguration/AWSCognitoPluginWebAuthnIntegrationTests-amplify_outputs.json
```