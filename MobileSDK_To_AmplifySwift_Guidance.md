# Migrating from AWS SDK for iOS to Amplify Swift

This guide helps you migrate your iOS app from the legacy AWS SDK for iOS to the modern [Amplify Swift](https://docs.amplify.aws/gen1/swift/) library. 

---

## General Migration Notes

- **Amplify Swift** is the recommended library for all new iOS/macOS/watchOS/tvOS development.
- For any AWS service not yet supported by Amplify, you can use the [AWS SDK for Swift](https://github.com/awslabs/aws-sdk-swift) or reference [Swift SDK code examples](https://github.com/awsdocs/aws-doc-sdk-examples/tree/main/swift).
- For IoT, migrate to the [AWS IoT Device SDK for Swift](https://github.com/aws/aws-iot-device-sdk-swift).
- Amplify will make a best-effort attempt to preserve user auth sessions during migration, but some users may need to re-authenticate.

## Choose Your Migration Path

### If you have an **existing Amplify Gen1 project**:
Continue using **Amplify Gen1** and follow the migration tables below. Your existing backend configuration and resources will work seamlessly with Amplify Swift.

### If you **don't have an Amplify project** or are starting fresh:
We recommend using **[Amplify Gen2](https://docs.amplify.aws/react/start/quickstart/)** for new projects. Gen2 provides a modern fullstack TypeScript developer experience with improved performance and simplified deployment.

> **Note**: This guide focuses on migrating to Amplify Gen1 to maintain compatibility with existing Amplify backends. For Gen2 migration guidance, see the [Gen2 documentation](https://docs.amplify.aws/react/start/quickstart/).

---

## Category‑by‑category migration

### Authentication

| AWS Mobile SDK for iOS                                                                                          | Amplify Swift                                                                                                     |
| --------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| [SignUp](https://docs.amplify.aws/gen1/swift/sdk/auth/working-with-api/#signup)                                 | [SignUp](https://docs.amplify.aws/gen1/swift/build-a-backend/auth/enable-sign-in/#register-a-user)               |
| [Confirm SignUp](https://docs.amplify.aws/gen1/swift/sdk/auth/working-with-api/#confirm-signup)                 | [Confirm SignUp](https://docs.amplify.aws/gen1/swift/build-a-backend/auth/enable-sign-in/#register-a-user)        |
| [Sign In](https://docs.amplify.aws/gen1/swift/sdk/auth/working-with-api/#signin)                                | [Sign In](https://docs.amplify.aws/gen1/swift/build-a-backend/auth/enable-sign-in/#sign-in-a-user)                |
| [Guest Access](https://docs.amplify.aws/gen1/swift/sdk/auth/guest-access/)                                      | [Guest Access](https://docs.amplify.aws/gen1/swift/build-a-backend/auth/enable-guest-access/)                     |
| [Federated Identities](https://docs.amplify.aws/gen1/swift/sdk/auth/federated-identities/)                      | [Federated Identities](https://docs.amplify.aws/gen1/swift/build-a-backend/auth/advanced-workflows/#identity-pool-federation) |
| [Custom Auth Flow](https://docs.amplify.aws/gen1/swift/sdk/auth/custom-auth-flow/)                              | [Custom Auth Flow](https://docs.amplify.aws/gen1/swift/build-a-backend/auth/sign-in-custom-flow/#configure-auth-category) |
| [Track/Remember Device](https://docs.amplify.aws/gen1/swift/sdk/auth/device-features/)                          | [Track/Remember Device](https://docs.amplify.aws/gen1/swift/build-a-backend/auth/remember-device/#configure-auth-category) |
| **Drop‑in UI** (Deprecated `AWSMobileClient`)                                                                   | [**Amplify UI Authenticator**](https://ui.docs.amplify.aws/swift/connected-components/authenticator)              |
| [Change Password](https://docs.amplify.aws/gen1/swift/sdk/auth/working-with-api/#force-a-password-reset)         | [Change Password](https://docs.amplify.aws/gen1/swift/build-a-backend/auth/manage-passwords/#change-password)     |
| [Forgot Password](https://docs.amplify.aws/gen1/swift/sdk/auth/working-with-api/#forgot-password)               | [Reset Password](https://docs.amplify.aws/gen1/swift/build-a-backend/auth/multi-step-sign-in/#reset-password)     |
| [Tokens & Credentials](https://docs.amplify.aws/gen1/swift/sdk/auth/working-with-api/#managing-security-tokens) | [Accessing Credentials](https://docs.amplify.aws/gen1/swift/build-a-backend/auth/accessing-credentials/)          |
| [Global SignOut](https://docs.amplify.aws/gen1/swift/sdk/auth/working-with-api/#global-signout)                 | [Global SignOut](https://docs.amplify.aws/gen1/swift/build-a-backend/auth/sign-out/#global-sign-out)              |
| [Hosted UI](https://docs.amplify.aws/gen1/swift/sdk/auth/hosted-ui/#using-auth0-hosted-ui)                      | [Sign in with Web UI](https://docs.amplify.aws/gen1/swift/build-a-backend/auth/sign-in-with-web-ui/)              |

> **Note** – Social sign‑in in Authenticator for SwiftUI is under active development; track progress in the [GitHub repo](https://github.com/aws-amplify/amplify-ui-swift-authenticator).

---

### Storage

| AWS Mobile SDK for iOS                                                                             | Amplify Swift                                                                                           |
| -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| [Upload File](https://docs.amplify.aws/gen1/swift/sdk/storage/transfer-utility/#upload-a-file)     | [Upload File](https://docs.amplify.aws/gen1/swift/build-a-backend/storage/upload/)                      |
| [Download File](https://docs.amplify.aws/gen1/swift/sdk/storage/transfer-utility/#download-a-file) | [Download File](https://docs.amplify.aws/gen1/swift/build-a-backend/storage/download/#download-to-file) |
| [Progress Tracking](https://docs.amplify.aws/gen1/swift/sdk/storage/transfer-utility/#track-transfer-progress) | Supported via completion handlers & async sequences                                                     |
| [Pause Transfers](https://docs.amplify.aws/gen1/swift/sdk/storage/transfer-utility/#pause-a-transfer), [Resume Transfers](https://docs.amplify.aws/gen1/swift/sdk/storage/transfer-utility/#resume-a-transfer) | [Pause/Resume](https://docs.amplify.aws/gen1/swift/build-a-backend/storage/download/#cancel-pause-resume) supported for downloads/uploads |
| [Cancel Transfers](https://docs.amplify.aws/gen1/swift/sdk/storage/transfer-utility/#cancel-a-transfer) | [Cancel](https://docs.amplify.aws/gen1/swift/build-a-backend/storage/download/#cancel-pause-resume) supported for downloads/uploads |
| [Transfer with Metadata](https://docs.amplify.aws/gen1/swift/sdk/storage/transfer-utility/#transfer-with-object-metadata) | Supported (`StorageUploadFileRequest.Options.metadata`) |
| Background Transfers                                                                               | Not currently supported in Amplify Swift ([see SDK doc](https://docs.amplify.aws/gen1/swift/sdk/storage/transfer-utility/#background-transfers)) |

---

### REST API

(Replace **AWSAPIGatewayClient**)

| AWS Mobile SDK for iOS                                      | Amplify Swift                                                                                                                                                                                                                                                                                                                                                           |
| ----------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Invoke](https://docs.amplify.aws/gen1/swift/sdk/api/rest/) | [Create](https://docs.amplify.aws/gen1/swift/build-a-backend/restapi/set-up-rest-api/#make-a-post-request) / [Fetch](https://docs.amplify.aws/gen1/swift/build-a-backend/restapi/fetch-data/) / [Update](https://docs.amplify.aws/gen1/swift/build-a-backend/restapi/update-data/) / [Delete](https://docs.amplify.aws/gen1/swift/build-a-backend/restapi/delete-data/) |
| [IAM Auth](https://docs.amplify.aws/gen1/swift/sdk/api/rest/#iam-authorization)                                                    | [Configure IAM](https://docs.amplify.aws/gen1/swift/build-a-backend/restapi/customize-authz/#iam-authorization)                                                                                                                                                                                                                                                         |
| [Cognito User Pools Authorization](https://docs.amplify.aws/gen1/swift/sdk/api/rest/#cognito-user-pools-authorization)                          | [Cognito User Pools Authorization](https://docs.amplify.aws/gen1/swift/build-a-backend/restapi/customize-authz/#cognito-user-pool-authorization)                                                                                                                                                                                                                                |

---

### GraphQL API

(Replace **AWSAppSyncClient**)

| AWS Mobile SDK for iOS | Amplify Swift                                                                                                           |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| [Run Queries](https://docs.amplify.aws/gen1/swift/sdk/api/graphql/#run-a-query), [Run Mutations](https://docs.amplify.aws/gen1/swift/sdk/api/graphql/#run-a-mutation) | [Query Data](https://docs.amplify.aws/gen1/swift/build-a-backend/graphqlapi/query-data/) / [Mutate Data](https://docs.amplify.aws/gen1/swift/build-a-backend/graphqlapi/mutate-data/) |
| [Subscriptions](https://docs.amplify.aws/gen1/swift/sdk/api/graphql/#subscribe-to-data)          | [Real‑time Subscribe](https://docs.amplify.aws/gen1/swift/build-a-backend/graphqlapi/subscribe-data/)                  |
| [Auth Modes](https://docs.amplify.aws/gen1/swift/sdk/api/graphql/#authorization-modes)             | [Configure Auth Modes](https://docs.amplify.aws/gen1/swift/build-a-backend/graphqlapi/customize-authz-modes/)          |

---

### Push Notifications

> **Pinpoint deprecation notice** – Pinpoint will be retired Oct 30 2026. Plan migrations accordingly.

| AWS SDK for iOS                                                                                                                      | Amplify Swift                                                                                                                        |
|-------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------|
| [Setup](https://docs.amplify.aws/gen1/swift/sdk/push-notifications/setup-push-service/)                                                | [Setup](https://docs.amplify.aws/gen1/swift/build-a-backend/push-notifications/set-up-push-notifications/)                          |
| [Push Notification Service Setup](https://docs.amplify.aws/gen1/swift/sdk/push-notifications/setup-push-service/)                   | [Push Notification Service Setup](https://docs.amplify.aws/gen1/swift/build-a-backend/push-notifications/set-up-push-service/)       |
| [Register Device](https://docs.amplify.aws/gen1/swift/sdk/push-notifications/messaging-campaign/)                                   | [Register Device](https://docs.amplify.aws/gen1/swift/build-a-backend/push-notifications/register-device/)                           |
| [Record Notification Events](https://docs.amplify.aws/gen1/swift/sdk/push-notifications/messaging-campaign/)                        | [Record Notification Events](https://docs.amplify.aws/gen1/swift/build-a-backend/push-notifications/record-notifications/)           |

---

### Analytics

> **Pinpoint deprecation notice** – Pinpoint will be retired Oct 30 2026. Plan migrations accordingly.

| AWS SDK for iOS                                                                                                   | Amplify Swift                                                                                                                        |
|-------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------|
| [Manually Track Session](https://docs.amplify.aws/gen1/swift/sdk/analytics/getting-started/#add-analytics)         | [Automatically Track Session](https://docs.amplify.aws/gen1/swift/build-a-backend/more-features/analytics/set-up-analytics/#initialize-amplify-analytics) |
| [Add Analytics](https://docs.amplify.aws/gen1/swift/sdk/analytics/getting-started/#add-analytics)                  | [Add Analytics](https://docs.amplify.aws/gen1/swift/build-a-backend/more-features/analytics/set-up-analytics/#initialize-amplify-analytics)                |
| [Authentication Events](https://docs.amplify.aws/gen1/swift/sdk/analytics/events/#authentication-events)                  | [Authentication Events](https://docs.amplify.aws/gen1/swift/build-a-backend/more-features/analytics/record-events/#authentication-events)                  |
| [Custom Events](https://docs.amplify.aws/gen1/swift/sdk/analytics/events/#custom-events)                           | [Custom Events](https://docs.amplify.aws/gen1/swift/build-a-backend/more-features/analytics/record-events/)                                               |

---

### AWS IoT

Amplify currently does **not** expose an IoT category. Use the standalone [**AWS IoT Device SDK for Swift**](https://github.com/aws/aws-iot-device-sdk-swift/blob/main/Package.swift), which works side‑by‑side with Amplify.

```swift
// Example: Connect & subscribe with AWS IoT Device SDK Swift
import AwsIot
...
```

---

## When Amplify doesn't cover a service

For AWS services without an Amplify category (e.g., Amazon SQS, EventBridge, DynamoDB Streams) import the **AWS SDK for Swift** directly.\
See runnable examples in the [aws‑doc‑sdk‑examples/swift](https://github.com/awsdocs/aws-doc-sdk-examples/tree/main/swift) repository.

> **Tip** – You can share credentials between Amplify and AWS SDK by passing `Amplify.Auth.fetchAuthSession()` credentials into service client configuration.

---

## Migration checklist

1. **Remove** SDK pods / SPM packages for `AWSMobileClient`, `AWSS3TransferUtility`, etc.
2. **Backend setup**:
   - **Existing Amplify Gen1 project**: Run `amplify pull` to download your configuration
   - **New project**: Set up [Amplify Gen2](https://docs.amplify.aws/react/start/quickstart/) or use existing AWS resources
3. **Add** Amplify Swift libraries and required plugins via SPM.
4. Initialize Amplify in your App's entry point.
5. Replace legacy calls using the tables above.
6. Build & test: verify
   - Existing users stay signed in
   - S3 uploads/downloads work
   - API calls succeed
   - Analytics events appear in Pinpoint

---

## FAQ

> **Can I mix AWS Mobile SDK for iOS and Amplify Swift (Amplify v2) in the same app?**
>
> **No.** AWS Amplify explicitly does **not** support using the AWS Mobile SDK for iOS and Amplify Swift (Amplify v2) together in the same app. This is due to overlapping implementations, conflicting dependencies, and import issues. Attempting to use both in the same project can result in unpredictable behavior, build errors, and runtime issues.
>
> For a successful migration, you must **fully remove** the AWS Mobile SDK for iOS from your project before integrating Amplify Swift (Amplify v2).

**Will my users be forced to sign in again?**\
No. When Amplify is pointed at the same Cognito User Pool and key‑chain location, it detects cached refresh tokens and continues the session automatically.

---

## Additional resources

- [Amplify Swift Upgrade Guide](https://docs.amplify.aws/gen1/swift/start/project-setup/upgrade-guide/)
- [Amplify UI Authenticator for Swift](https://github.com/aws-amplify/amplify-ui-swift-authenticator)
- [AWS IoT Device SDK for Swift announcement](https://aws.amazon.com/blogs/developer/introducing-the-aws-iot-device-sdk-for-swift-developer-preview/)

---

© Amazon Web Services 2025 – Documentation links verified **July 16 2025**. 