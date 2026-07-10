# AmplifyConnectClient Integration Tests

## Prerequisites

- Node.js 20+ (Node 22 recommended)
- AWS credentials configured (`~/.aws/credentials` or environment variables)
- An Amplify Gen2 backend deployed with `defineNotifications()`

## Backend Setup

There are two setup paths depending on whether you already have an Amazon Connect instance with Customer Profiles.

---

### Option A: Create from scratch (no existing Connect setup)

This is the zero-config path. It provisions a new Connect instance, Customer Profiles domain, and all required resources automatically.

#### 1. Create a new Amplify project

```bash
npm create amplify@latest
```

#### 2. Add notifications to the backend

`npm create amplify@latest` scaffolds auth automatically. Install the notifications package and update `amplify/backend.ts`:

```bash
npm install @aws-amplify/backend-notifications
```

**`amplify/backend.ts`:**
```typescript
import { defineBackend } from '@aws-amplify/backend';
import { defineNotifications } from '@aws-amplify/backend-notifications';
import { auth } from './auth/resource';

const backend = defineBackend({
  auth,
  notifications: defineNotifications(),
});
```

#### 3. Deploy the sandbox

```bash
npx ampx sandbox
```

This creates:
- Cognito User Pool + Identity Pool (with guest access enabled)
- Amazon Connect instance
- Customer Profiles domain with `AmplifyProfile`, `AmplifyGuestProfile`, `AmplifyDevice` object types
- HTTP API with `POST /identify-user` (JWT auth) and `POST /identify-user-guest` (IAM/SigV4)
- Push handler Lambda + End User Messaging application

---

### Option B: Attach to an existing Connect Customer Profiles domain

If you already have an Amazon Connect instance with Customer Profiles enabled, you can attach to the existing domain instead of creating a new one.

#### 1. Create a new Amplify project

```bash
npm create amplify@latest
```

#### 2. Add notifications with your existing domain name

```bash
npm install @aws-amplify/backend-notifications
```

**`amplify/backend.ts`:**
```typescript
import { defineBackend } from '@aws-amplify/backend';
import { defineNotifications } from '@aws-amplify/backend-notifications';
import { auth } from './auth/resource';

const backend = defineBackend({
  auth,
  notifications: defineNotifications({
    // Attach to your existing Customer Profiles domain.
    // This registers the AmplifyProfile/AmplifyDevice/AmplifyGuestProfile
    // object types into your domain without creating a new Connect instance.
    domainName: 'your-existing-profiles-domain',
  }),
});
```

> **Note:** In attach mode, the construct registers the required object types
> into your domain additively. It does not create a Connect instance or modify
> existing integrations (CTR, Outbound Campaigns, Identity Resolution).
> Associating the domain with Outbound Campaigns for Journey targeting remains
> your responsibility.

#### 3. Deploy the sandbox

```bash
npx ampx sandbox
```

---

## Post-Deploy Steps (both options)

### 4. Copy `amplify_outputs.json`

Copy the generated `amplify_outputs.json` to the shared test configuration directory
with the test-specific name:

```bash
mkdir -p ~/.aws-amplify/amplify-ios/testconfiguration
cp amplify_outputs.json ~/.aws-amplify/amplify-ios/testconfiguration/AmplifyConnectClientIntegrationTests-amplify_outputs.json
```

The host app's build phase script automatically copies files from
`~/.aws-amplify/amplify-ios/testconfiguration/` into the test bundle at build time.

The file should have this structure:

```json
{
  "auth": {
    "user_pool_id": "us-west-2_XXXXXXXXX",
    "aws_region": "us-west-2",
    "user_pool_client_id": "...",
    "identity_pool_id": "us-west-2:...",
    "unauthenticated_identities_enabled": true
  },
  "version": "1.4",
  "custom": {
    "CustomerProfiles": {
      "endpoint": "https://<api-id>.execute-api.<region>.amazonaws.com",
      "region": "<region>"
    }
  }
}
```

### 5. Create a test user and credentials file

```bash
# Sign up
aws cognito-idp sign-up \
  --client-id <user_pool_client_id> \
  --username integ-test@example.com \
  --password 'IntegTest1234!' \
  --user-attributes Name=email,Value=integ-test@example.com \
  --region <region>

# Confirm
aws cognito-idp admin-confirm-sign-up \
  --user-pool-id <user_pool_id> \
  --username integ-test@example.com \
  --region <region>
```

Then create a credentials JSON file:

```bash
cat > ~/.aws-amplify/amplify-ios/testconfiguration/AmplifyConnectClientIntegrationTests-credentials.json << 'EOF'
{
  "username": "integ-test@example.com",
  "password": "IntegTest1234!"
}
EOF
```

### 6. Run integration tests

Open the host app project in Xcode and run the `ConnectClientIntegrationTests` scheme:

```bash
open AmplifyClients/AmplifyConnectClient/Tests/ConnectClientHostApp/ConnectClientHostApp.xcodeproj
```

Or via command line:

```bash
xcodebuild test \
  -project AmplifyClients/AmplifyConnectClient/Tests/ConnectClientHostApp/ConnectClientHostApp.xcodeproj \
  -scheme ConnectClientIntegrationTests \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Enabling Push Notifications (optional)

To test end-to-end push delivery via Connect Journeys:

1. Store your APNs/FCM credentials as Amplify secrets:
   ```bash
   npx ampx sandbox secret set APNS_SIGNING_KEY      # paste .p8 contents
   npx ampx sandbox secret set FCM_SERVICE_ACCOUNT_JSON  # paste service-account JSON
   ```

2. Add channel config to `defineNotifications`:
   ```typescript
   notifications: defineNotifications({
     apns: {
       keySecret: secret('APNS_SIGNING_KEY'),
       keyId: 'ABC123DEFG',
       teamId: 'DEF456GHIJ',
       bundleId: 'com.example.app',
     },
   }),
   ```

3. Redeploy: `npx ampx sandbox`

4. Create a Journey in the Connect console targeting your profiles with a
   push custom-action step.

---

## Verifying Results

After running `identifyUser`, verify the profile was created:

1. AWS Console → **Amazon Connect** → your instance → **Customer Profiles**
2. Search by userId or email
3. Confirm the profile has the expected attributes and device objects

---

## Teardown

```bash
npx ampx sandbox delete --yes
```

This removes all provisioned resources (Connect instance, Customer Profiles domain, Lambdas, API Gateway, Cognito). If using attach mode, the existing domain is not deleted — only the Amplify-registered object types are removed.
