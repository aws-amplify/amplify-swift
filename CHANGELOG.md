# Changelog

## 2.11.2 (2023-05-18)

### Bug Fixes

- **Auth**:  Revert - fix(Auth): Use correct queries when getting and setting keychain items (#2975)

## DEPRECATED - 2.11.1 (2023-05-17)

### Bug Fixes

- **Auth**: Use correct queries when getting and setting keychain items (#2965)

## 2.11.0 (2023-05-16)

### Features

- **auth**: deprecate AWSAuthSignInOptions.validationData (#2955)
- **storage**: Added support for AWSStorageGetURLOptions.validateObjectExistence

### Bug Fixes

- **datastore**: stop datastore plugin only stops syncEngine (#2942)
- liveness service error reporting (#2937)

## 2.10.0 (2023-05-04)

### Features

- upgrade to aws-sdk-swift version 0.13.0 (#2783)

## 2.9.1 (2023-05-02)

### Bug Fixes

- **Auth**: Fixing throwing of AuthError when Authorization fails during signIn (#2905)
- **storage**: foreground upload speed (#2925)

## 2.9.0 (2023-04-28)

### Features

- **predictions**: add predictions v2 (#2902)

## 2.8.1 (2023-04-17)

### Bug Fixes

- **Auth**: Fixing handling of service SdkError in Auth tasks (#2859)
- **predictions**: make predictions plugin init internal (#2855)

## 2.8.0 (2023-04-05)

### Features

- **liveness**: add session + websocket client (#134)
- **liveness**: add spi models (#132)
- **predictions**: add support for sigv4 signing (#130)
- **predictions**: EventStream Encoding and Decoding Support (#129)

### Bug Fixes

- **liveness**: misc minor changes (#135)
- **storage**: Ensure progress from Amplify.Storage.uploadFile completes

## 2.7.1 (2023-03-28)

## 2.7.0 (2023-03-28)

### Features

- **storage**: Add pagination support.

### Bug Fixes

- **datastore**: detect duplicate mutation event by both modelName and modelId (#2834)
- **Auth**: Adding ASF DeviceId as an input for Cognito APIs (#2833)
- **PushNotifications**: Checking if there is a Provisioning Profile with the APS Entitlement in order to determine the ChannelType (#2824)

## 2.6.1 (2023-03-21)

### Bug Fixes

- **datastore**: swap `like` for `instr` in sql queries (#2818)
- **storage**: update storage to support downloading if a file already exist locally (#2825)
- **Auth**: Sign out when user does not exist during delete user task (#2812)

## 2.6.0 (2023-03-13)

### Features

- **datastore**: add notContains query operator (#2789)

### Bug Fixes

- **Auth**: Adding missing Authorization header when a Client Secret is defined. (#2807)

## 2.5.0 (2023-03-08)

### Features

**PushNotifications**: Add Amplify Push Notifications category and AWSPinpoint Push Notifications plugin. [(#2794)](https://github.com/aws-amplify/amplify-swift/pull/2794)

The **Push Notifications** category allows you to integrate push notifications in your app with Amazon Pinpoint targeting, campaign, and journey management support. You can segment your users, trigger push notifications to your app, and record metrics in Pinpoint when users receive or open notifications.  We use Amazon Pinpoint since it helps you to create messaging campaigns and journeys targeted to specific user segments or demographics and collect interaction metrics with push notifications. 

## 2.4.2 (2023-03-08)

### Bug Fixes

- **api**: Remove optional cleanUp() method from AWSAPIPlugin.reset() (#2585)

## 2.4.1 (2023-03-06)

### Bug Fixes

- **datastore**: mutation event got ignored while executing parallel saving (#2781)
- upgrade to aws-sdk-swift v0.6.1 (#2774)
- **auth**: Build failure due to typo in device binding (#2719)
- **auth**: Device binding add retry incase of device not found (#2699)
- **auth**: Pass deviceMetadata in RespondToAuthChallenge for signIn challenges
- **auth**: Remove static deviceMetaData in auth flow (#2694)
- **api**: build selection set bottom up (#2763)

## 2.4.0 (2023-02-08)

### Features

- DataStore and API Lazy Loading with Custom Selection Set (#2583)

### Bug Fixes

- **test**: DS transformer V2 tests should be update mutation on existing model (#2753)
- **test**: compare model identifier for deletion events (#2752)
- **datastore**: load hasOne and belongsTo lazy reference with composite key (#2737)
- DefaultModelProvider return nil from not loaded state (#2746)
- CPK uni-directional has-many lazy list load (#2730)
- do not set nil values for create mutation graphQL input translation (#2701)
- Add missing PropertyPath types double and int (#2689)
- **datastore**: observe API mutation event decode to model successfully (#2684)

## 2.3.2 (2023-02-03)

### Bug Fixes

- **api**: add default user-agent header to API subscription requests (#2709)
- **auth**: Delete user api get stuck on no network (#2656)
- **auth**: Unblock fetchAuthSession call during a signIn flow (#2687)

## 2.3.1 (2023-01-18)

### Bug Fixes

- **API**: remove encoding step before feeding request to signer (#2666)

## 2.3.0 (2023-01-18)

### Features

- **api**: Update url cache for storage and api to nil (#2647)

### Bug Fixes

- **datastore**: skip has-many model to graphQL translation (#2661)
- **auth**: Return session expired on revoke token (#2652)
- **core**: Add proper handling of expired credentials (#2637)
- Add missing integration test scheme for Storage and Analytics (#2646)
- Change Integration Test Github action to run only integration test scheme (#2645)
- upgrade to aws-sdk-swift v0.6.0 (#2620)

## 2.2.1 (2022-12-19)

### Bug Fixes

- **auth**: Enable retrying when confirm signIn fails (#2617)
- **auth**: Remove parallel event that move auth plugin to an error state and other cleanups (#2612)
- **auth**: Enable signIn restart while another signIn is in progress (#2609)

## 2.2.0 (2022-12-05)

### Features

- **Auth**: Adding Auth test cases for test harness (#2579)
- **auth**: Make the presentation anchor optional (#2545)

### Bug Fixes

- **Auth**: Add correct validation for initial state when executing confirm sign in (#2587)
- **Auth**: Fixing deviceSRP auth flow during MigrateAuth (#2584)
- **datastore**: retry on subscription connection error (#2571)

## 2.1.0 (2022-11-10)

### Features

- **storage**: Remove the async throws from the apis that return task (#2543)

### Bug Fixes

- **datastore**: improve sync event error handling - cannotParseResponse (#2536)
- **datastore**: fix stop then start API call pattern (#2529)

### Features

- **storage**: Remove `async throws` from public apis that returns a task (#2543). The change avoids checking for error at two places and the api will become sync. 
              **Note:** This change would break customer who use storage api and have Xcode setting to treat warnings as error. 

## 2.0.2 (2022-11-02)

### Bug Fixes

- **auth**: Add secrethash to the resetPassword/resendSignUpCode (#2528)

## 2.0.1 (2022-10-27)

### Bug Fixes

- **Analytics**: Making connectivity errors to be retried indefinitely (#2497)
- Build failure in xcode 13.4 (#2498)
- **Auth**: Making improvements to federation flow (#2488)
- **analytics**: revert previous analytics limit commit (#2484)
- **analytics**: update pinpoint event attribute limits to match docum (#2474)
- Make AWSPluginsCore public (#2472)

## Unreleased

## 2.0.0 (2022-10-17)

### Breaking Changes
- **Core**: 
    - Updated all public apis to use the latest Swift concurrency features (Async/Await)
    - Removed dependency from aws-sdk-ios from all plugins
    - Cocoapods support is removed from v2.0.0

- **Analytics**: 
    - `identifyUser(:withProfile:)` has been renamed to `identifyUser(userId:userProfile:)`
    - Removed support for different Analytics and Targeting regions
    
- **Predictions**:
    - Predictions plugin is currently unavailable for this version
    
### Features
- **Auth**: 
    - Escape hatch apis for federation to Cognito Identity Pool
    - Custom auth flow now support without SRP flow
    - Supports user migration flow

- **Analytics**: 
    - Pinpoint APIs available through the escape hatch

- **Storage**:
    - Migrated storage plugin from TransferUtility

## 1.27.1 (2022-07-22)
### Bug Fixes
- **Auth:** Mapping correct error when Device Operations fail due to user not signed in (#2023).

## 1.27.0 (2022-07-14)

### Features

- **api**: AppSyncRTC 2.0.0 upgrade - Handle unauthorized connection (#1994)

### Bug Fixes

- **Auth**: Handling proper error when attempting to change password fails due to an expired session. (#1995)
- **datastore**: stop sync engine on non-retryable errors to allow restart (#1901)
- **datastore**: query for missing optional associations (#1849)
- **datastore**: Test schema drift does not restart sync engine (#1868)

## 1.26.2 (2022-06-10)

### Bug Fixes

- **datastore**: create pointer to temporal lock (#1883)

## 1.26.1 (2022-06-02)

### Bug Fixes

- **datastore**: ModelSyncedEvent dispatch consistency (#1823)

## 1.26.0 (2022-05-26)

### Features

- **DataStore**: Temporal performance enhancements (#1760)

### Bug Fixes

- **DataStore**: include table name inside quotes in SQL Update statement (#1824)

## 1.25.0 (2022-05-19)

### Features

- **auth**: Add support for authType as runtime parameter (#1774)

## 1.24.1 (2022-05-13)

### Bug Fixes

- **Auth**: Fixing a typo in the Auth error message (#1782) (#1798)
- **DataStore**: retry on URLError.dataNotAllowed (#1791)
- **DataStore**: retry initial sync network failures from RemoteSyncEngine (#1773)

## 1.24.0 (2022-05-05)

### Features

- **auth**: Add support of custom endpoint for CognitoUserPool (#1715)

## 1.23.2 (2022-05-04)

### Bug Fixes

- **DataStore**: Nesting DataStore integration tests (#1757)

## 1.23.1 (2022-04-25)

### Bug Fixes

- **DataStore**: Cascade delete sync from children to parent models (#1731)

## 1.23.0 (2022-04-12)

### Features

- **DataStore**: DataStore.delete(modelType:where:) API (#1723)

### Bug Fixes

- **build**: remove ungated  >= Swift 5.4 features to allow building on Xcode 12 (#1737)

## 1.22.4 (2022-04-07)

### Bug Fixes

- **analytics**: Set pinpointConfiguration.debug on debug mode (#1689)
- **DataStore**: Reconcile locally sourced mutations while subscriptions are disabled (#1712)

### ⚠ BREAKING CHANGES
- The escape hatch of Auth and Storage plugins now returns the underlying Swift SDK instead of AWSMobileClient and AWSTransferUtility.
- Logging category loglevel enum were moved to Amplify class extension to namespace them.

### Features

- **Core**: Amplify now directly depends on AWS SDK for Swift.
- **Auth**: Redesigned AWSCognitoAuthPlugin implementation using a state machine architecture. Internal dependency on AWSMobileClient is removed and the plugin directly depends on AWS SDK for Swift. The escape hatch now returns the underlying Swift SDK for Cognito UserPool and Cognito Identity Pool.
- **Storage**: Removed the dependency on AWSTransferUtility and improved the internal logic of AWSS3StoragePlugin implementation.

## 1.22.3 (2022-04-02)

## 1.22.2 (2022-03-29)

### Bug Fixes

- update SQLite dependency to 0.13.2 (#1696)

## 1.22.1 (2022-03-23)

## 1.22.0 (2022-03-16)

### Features

- **DataStore**: Create SQLite indexes when setting up datastore (#1634)

### Bug Fixes

- **DataStore**: Clear API should delete local store (#1685)
- **API**: DataRace - subscription cancel and OperationTaskMapper on reset (#1684)
- **DataStore**: Debugging - Access DB File path (#1678)
- **DataStore**: ObserveQuery InitialQuery empty modelIds set (#1663)
- **DataStore**: FatalError accessing SQLite connection (#1671)
- **DataStore**: add logging with model name for failed subscription request (#1665)
- **DataStore**: enable thread sanitzer, fix data races (#1656)
- **auth**: fix deleteUser Combine support (#1652)

## 1.21.0 (2022-02-23)

### Features

- **auth**: handle errors returned from Social SignIn sessions (#1642)

## 1.20.0 (2022-02-23)

### Features

- **API**: Set AppSyncRTClient log level from Amplify log level (#1637)

### Bug Fixes

- Handle .all predicate for create/update (#1640)

## 1.19.2 (2022-02-07)

### Bug Fixes

- **datastore**: Add DateTime, Date, Time, Int, Float, Enum field in indexes to GraphQL input correctly for mutations (#1612)

## 1.19.1 (2022-02-01)

### Bug Fixes

- **auth**: handle deleted account when fetching signed in session (#1604)

## 1.19.0 (2022-01-20)

### Features

- **auth**: add deleteUser API (#1598) [skip-ci]

## 1.18.3 (2022-01-20)

### Features

- **auth**: add deleteUser API (#1582)
- Update AWS SDKs to 2.27.0 (#1596)

## 1.18.2 (2022-01-19)

### Bug Fixes

- **datastore**: quote table name in create table-references SQL statement (#1485)

## 1.18.1 (2021-12-15)

## 1.18.0 (2021-12-15)

### Features

- **AWSPluginsCore**: Add non-blocking methods to AWSAuthServiceBehavior / deprecate existing blocking methods   (#1502)

### Bug Fixes

- **API**: Memory leak in GraphQLOperation (#1562)
- **Storage**: Use async getidentityid (#1544)

## 1.17.0 (2021-12-07)

### Features

- **Storage**: Add async resolvePrefix (#1539)

### Bug Fixes

- **datastore**: fix owner based subscriptions queries w/ multiauth (#1553)
- **auth**: Update the Auth plugin to enforce ordering of api calls (#1549)
- **DataStore**: Remove from snapshot when item no longer matches predicate (#1522)


### Features

- **Core**: Supports SwiftUI by not running `Amplify.configure` while running for Previews #1509


## 1.16.1 (2021-11-19)

## 1.16.0 (2021-11-18)

### Features

- **Geo**: Add Amplify Geo Category. Amplify Geo provides APIs for mobile app development such that you can add maps and search to your app with just a few lines of code.

### Bug Fixes

- **DataStore**: support predicate evaluation on model with Enum (#1516)

## 1.15.6 (2021-11-15)

### Bug Fixes

- **DataStore**: clear ModelSyncMetadata on duplicate ids found (#1515)
- **DataStore**: Allow different model types with the same ID (#1490)

## 1.15.5 (2021-11-04)

### Bug Fixes

- **DataStore**: ModelSyncedEventEmitter event order (#1494)

## 1.15.4 (2021-11-03)

### Bug Fixes

- Support new list name pluralization (#1451)

## 1.15.3 (2021-10-21)

### Bug Fixes

- **DataStore**: Optimize mutation event propagation after model synced in ModelSyncEventEmitter (#1479)
- **datastore**: Fixes SPM build error due to missing import Foundation in SyncEventEmitter.swift (#1481)
- **auth**: Replace force unwrap to throw an error in AWS credentials (#1476)
- **DataStore**: ModelSyncedEvent before last MutationEvent (#1472)
- **DataStore**: Reconciliation path avoid model.modelName (#1475)
- **DataStore**: Improve ObserveQuery for multiple sort input (#1464)

## 1.15.2 (2021-10-14)

### Bug Fixes

- **DataStore**: Fallback when missing auth rule providers to API requirements (#1465)

## 1.15.1 (2021-10-14)

### Bug Fixes

- **DataStore**: ObserveQueryOperation missing import for SPM (#1470)

## 1.15.0 (2021-10-12)

### Features

- **DataStore**: ObserveQuery API (#1422)

### Bug Fixes

- **datastore**: require auth plugin if provider is nil in sync-requirements (#1461)
- **datastore**: Sync engine fallback to API plugin config (#1460)
- **DataStore**: Avoid model name from mutation sync in ModelSyncedEventEmitter (#1454)

## 1.14.0 (2021-09-28)

### Features

- **Storage**: AWSS3PluginPrefixResolver (#1277)

### Bug Fixes

- **Logging**: fix concurrency issues with logLevel (#1431)
- **Datastore**: Consecutive Updates (Save, Sync, Update and Immediately Delete Scenario) (#1407)
- **DataStore**: ReconcileAndLocalSave schedule on internal queue (#1415)

## 1.13.4 (2021-08-25)

### Features
- Update AWS SDKs to 2.25.0 (#1395)

## 1.13.3 (2021-08-07)

### Bug Fixes

 - **DataStore**: add missing SQLite3 import (#1368)
 - **DataStore**: storage engine doesn't need auth plugin for api key (#1366)

## 1.13.1 (2021-08-05)

### Bug Fixes

- **Datastore**: consecutive updates nil version scenario (#1333)
- **DataStore**: Various mutation sync fixes (#1355)
- **DataStore**: do not send completion event to publisher on DataStore.clear() and DataStore.stop() (#1273)
- Fix data store mutation when restoring network (#1345)
- **DataStore**: drop failed constraint violation reconciliations (#1321)

## 1.13.0 (2021-07-30)

### Features

- support for lambda authorizer (#1334)

### Bug Fixes

- **amplify-xcode**: add files to primary target (#1313)
- **DataStore**: dynamic model support for cascade delete (#1296)

## 1.12.0 (2021-06-28)

### Features

- **datastore**: multi-auth support (#1260)

### Bug Fixes

- **datastore**: initalSync should be successful in case of unauthorized errors (#1299)

## 1.11.0 (2021-06-23)

### Features

- **api**: fix querystring encoding according to AWS SigV4 (#1068)

### Bug Fixes

- GraphQLBuilder use model name from schema instead of model (#1292)
- **api**: interceptors refactoring (#1247)
- **Model**: Apply codegen changes test models (#1145)

## 1.10.0 (2021-06-10)

### Features

- **DataStore**: Multiple models ReconcileAndLocalSave transaction (#1237)
- **datastore**: support for @auth provider attribute (#1258)
- **datastore**: support mutation (deletion) with custom primary keys (#1228)

### Bug Fixes

- increase sync concurrency count based on associations (#1267)

## 1.9.3 (2021-05-26)

### Bug Fixes

- Quote table names in CreateTableStatement (#1233)
- **DataStore**: redundant local metadata query in ReconcileAndLocalSaveOperation (#1217)

## 1.9.2 (2021-05-13)

### Bug Fixes

- **DataStore**: log metrics for ReconcileAndLocalSaveOperation (#1215)
- Pass additional info in signIn next step (#1201)

## 1.9.1 (2021-05-05)

### Bug Fixes

- **API**: Reachability resolve to GraphQL API (#1167)
- **auth**: pass public challenge parameters in nextstep when authenticating with custom challenge
- SQLLite dependency exact 0.12.2 version (#1199)
- AppSyncRealTimeClient dependency up to next major (#1198)

## 1.9.0 (2021-04-26)

### Features

- Update SDK to 2.24.0 and add override in AmplifyAWSServiceConfiguration (#1184)
- **datastore**: support for readonly fields (#1133)

## 1.8.1 (2021-04-15)

### Bug Fixes

- Throw error when plugin added post-configure (#1150)
- **API**: Subscriptions with IAM match signed headers (#1139)

## 1.8.0 (2021-04-07)

### Features

- Amplify iOS can now be installed via Swift Package Manager. See the [README](https://github.com/aws-amplify/amplify-ios/blob/main/README.md) for full details. (#1146)

## 1.7.2 (2021-04-02)

### Bug Fixes

- **DataStore**: remove reconcile operations serially (#1137)

## 1.7.1 (2021-04-01)

### Bug Fixes

- **datastore**: fix selective sync expressions to run DDB query when possible (#1100)
- **DataStore**: Reconcile and save serially (#1128)
- **auth**: handle tooManyRequests and limitExceeded separately in AuthErrorHelper (#1122)

## 1.7.0 (2021-03-19)

### Features

- **datastore**: process OperationDisabled error (#1104)
- **amplify-xcode**: generate JSON schema (#1080)

### Bug Fixes

- **API**: Return response body for non-2xx failure cases (#1076)
- **auth**: update warn to log for identity pool config (#1081)

## 1.6.1 (2021-02-19)
### Misc updates
- Amplify/Tools pod is currently deprecated and it will be completely removed in a future release. For now, Xcode will emit a deprecation warning if your project invokes AmplifyTools in a custom build phase.

## 1.6.0 (2021-02-04)

### Features

- Support lazy load and pagination for API (#1009)
- Separate DataStore List logic out to list provider (#1000)

### Behavior Change

- **Auth**: Fix cancelling hostedUI returning a generic error (#982).

    When a user cancels the sign in flow from `Amplify.Auth.signInWithWebUI`, the callback will now deliver an error of type `AuthError.service`, with an underlying error of `AWSCognitoAuthError.userCancelled`. Previously, the error was a `SFAuthenticationError.canceledLogin`. The `AuthError.service` error type will be returned regardless of whether the underlying HostedUI operation was performed via an SFAuthenticationSession or an ASWebAuthenticationSession.
    
    You can detect the user cancellation case by `switch`ing on the error, as in:
    
    ```swift
    switch result {
      case .success:
          print("SignOut")
      case .failure(let error):
          if case AuthError.service(_, _, let underlyingError) = error,
              case .userCancelled = (underlyingError as? AWSCognitoAuthError) {
              print("User cancelled")
          }
    }
    ```

### Misc updates

- **Auth**: `Amplify.Auth.signInWithWebUI` now automatically uses `ASWebAuthenticationSession` internally for iOS 13.0+. For older iOS versions, it will fall back to `SFAuthenticationSession`.
    This release also introduces a new `preferPrivateSession` flag to `AWSAuthWebUISignInOptions` during the sign in flow. If `preferPrivateSession` is set to `true` during sign in, and the user's preferred browser supports [`ASWebAuthenticationSession.prefersEphemeralWebBrowserSession`](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession/3237231-prefersephemeralwebbrowsersessio), the user will not see a web view displayed when they sign out. 

    ```swift
    Amplify.Auth.signInWithWebUI(presentationAnchor: self.view.window!, 
                                options: .preferPrivateSession()) { ... }
    ```

## 1.5.5 (2021-01-26)

### Bug Fixes

- **AWSAPIPlugin**: Update dependencies to consume AppSyncRealTimeClient race condition fix (#1038)
- **datastore**: delete model with predicate (#1030)

## 1.5.4 (2021-01-21)

### Bug Fixes

- **DataStore**: Generate mutation events for associatedModels (#987)
- **DataStore**: support for QueryPredicateConstant.all for graphql queries (#1013)

## 1.5.3 (2021-01-09)

### Bug Fixes

- **Model**: retrieve correct associated target name (#965)

## 1.5.2 (2020-12-24)

### Bug Fixes

- **DataStore**: QueryPredicate translation (#961)
- refactor GraphQL response decoder (#971)
- add blog post comment schema and tests (#970)
- **Auth**: Dismiss empty UIViewController (#947)
- Add plugin conformances to AmplifyVersionable (#941)

## 1.5.1 (2020-12-11)

### Bug Fixes

- **predictions**: use string's unicode scalars view to compute indexes for Comprehend results (#904)
- **Predictions**: Callback is not triggered with URLError (#896)
- **amplify**: DataStore query fix column missing issue for @connection hasMany schema (#885)
- add targetName to hasOne relationships (#926)
- **API**: Fix unstable AWSAPICategoryPluginResetTests.testReset() (#937)

## 1.5.0 (2020-12-03)

### Features

- **datastore**: selective sync on initial sync & incoming subscription models (#884)
- **DataStore**: Start/Stop implementation (#919)
  - **Note:** In previous releases, the DataStore sync engine was started automatically on `Amplify.configure()`. With this release, the DataStore sync engine does not start on `Amplify.configure()`.  More information can be found in the documentation [here](https://docs.amplify.aws/lib/datastore/other-methods/q/platform/ios#start).


### Bug Fixes

- **API**: subscription cancel unit test failing intermittently (#927)
- **auth**: Fix an issue where the fetchAuthSession callback is called twice (#922)
- **DataStore**: SyncMutationToCloudOperationTests thread sanitizer bug (#915)
- **Predictions**: Avoid Multiple Rekognition Error Return (#910)
- **Predictions**: Fix of PredicationPlugin unit tests (#903)
- Use correct category plugins to populate dev menu (#897)
- **DataStore**: Nested query predicates are not stored properly (#905)

## 1.4.4 (2020-11-19)

### Bug Fixes

- Designate SwiftUI a weak_framework in podspec (#892)

## 1.4.3 (2020-11-13)

### Bug Fixes

- **DataStore**: failed subscriptions lead to instability in sync engine (#889)

## 1.4.2 (2020-11-11)

### Bug Fixes
- **amplify**: change reset method (#866)
- **datastore**: Fix regression caused by changing the public enum value (#883)

## 1.4.1 (2020-11-05)

This version has been deprecated. Please use the latest release.

## 1.4.0 (2020-10-23)

### Features

- **dev-menu**: add the Developer Menu to Amplify (#844)
- **datastore**: DataStore Hub events (#766) (#795)

### Bug Fixes

- **Core**: use groupClaim in @auth rule for oidc (#847)
- **API**: Support for auth api oidc provider (#842)
- **api**: make sure collections are not in the gql input - fixes #828 (#837)
- replace fastlane warn method (#835)

## 1.3.2 (2020-10-16)

### Bug Fixes

- move AWSServiceConfiguration Platform extension (#832)
- auth category should throw AuthError instead of PredictionsError (#830)
- **DataStore**: Owner and Group Combined @auth (#817)
- **auth**: rename conflicting name AWSAuthService to AWSCognitoAuthService (#824)
- **datastore**: Keep DataStore sync engine running even if models subscriptions fail (#815)
- **auth**: Dismiss UI first before sending callback for HostedUI (#820)
- **Core**: support for custom identity claim (#813)
- Parse and surface returned subscription @auth errors (#810)
- **Core**: support identityClaim "sub" (#794)
- **DataStore**: owner based auth, read operations (#788)

## 1.3.1 (2020-10-01)

### Bug Fixes

- Data race in AWSModelReconciliationQueue (#790)
- Remove unused RepeatingTimer (#786)

## 1.3.0 (2020-09-29)

### Features

- Support Xcode 12 (#779)
- **datastore**: Dispatch outboxMutationEnqueued, outboxMutationProcessed events (#759)

### Bug Fixes

- Remove enableThreadSanitizer flag from test invocation (#783)
- Add #if swift check for Combine publishers (#775)

## 1.2.0 (2020-09-16)

### Features

- **DataStore**: Dispatch outboxStatus, subscriptionsEstablished, syncQueriesStarted events ([#721](https://github.com/aws-amplify/amplify-ios/pull/721))

### Bug Fixes

- **DataStore**: Fix publishing events from model reconciliation queue ([#756](https://github.com/aws-amplify/amplify-ios/pull/756))
- **Core**: Fix default operator outside of guard statement ([#752](https://github.com/aws-amplify/amplify-ios/pull/752))

## 1.1.2 (2020-08-30)

### Bug Fixes

- **Auth**: Updated AWS SDK dependencies to fix crash during `federatedSignIn` (#640)
- **API**: Add custom 'items' deserialization for List (#711)
- Fix typo in iOS Combine docs (#747)

## 1.1.1 (2020-08-18)

### Bug Fixes

- Propagate @discardableResult to implementations (#719)

## 1.1.0 (2020-08-12)

### Features

- **auth**: Add metadata options for passing clientMetadata to APIs (#700)
- Add Combine support (#667)
- Mark APIs that return operations with @discardableResult (#633)
- Add AmplifyConfiguration file-based initializer (#707)

### Bug Fixes

- **Predictions**: rowIndex and columnIndex for cell (#704)
- **predictions**: TABLE, CELL & KEY_VALUE_SET blocks are not properly processed (#660)
- **api**: cognito user pool intercept with accessToken (#690)

## 1.0.6 (2020-08-03)

### Bug Fixes

- Update AppSyncRealTimeClient dependency (#683)

## 1.0.5 (2020-07-24)

### Bug Fixes

- **auth**: missing initializers for AWSAuth*Options (#658)
- **storage**: delete file if key not found on download (#652)
- Fix cancellation logic for AWSGraphQLSubscriptionOperation (#650)
- Plugins that are not configured correctly will be error at initial step (#642)
- **Datastore**: paginationInput not passed down in query (#647)
- **auth**: Fix an issue that prevents signInWithWebUI to present over a presenting vc (#635)
- **auth**: User pool token, user sub should be returned for signedIn user with no identityPool config (#632)

## 1.0.4 (2020-07-01)

### Bug Fixes

- DataStore E2E Integration Tests ([#596](https://github.com/aws-amplify/amplify-ios/pull/596))
- Auth updated the AWSMobileClient version to 2.14.0 to fix a crash related to nil user pool client ([#592](https://github.com/aws-amplify/amplify-ios/issues/592))

## 1.0.3 (2020-06-26)

### Bug Fixes

* **Auth** Fix issue in auth configure where it fails if one of the Cognito services is not present. ([#586](https://github.com/aws-amplify/amplify-ios/issues/586))

## 1.0.2 (2020-06-25)

### Bug Fixes

* **Auth** Signout will completely delete the session in webui ([#542](https://github.com/aws-amplify/amplify-ios/pull/542))
* **Core** Fix plugin configuration validation ([#543](https://github.com/aws-amplify/amplify-ios/pull/543))
* **DataStore** Fixed a DataStore issue where lazy `List<M>` initialization would fail for relationships 3+ levels deep ([#534](https://github.com/aws-amplify/amplify-ios/pull/534))
* **DataStore** Model schema updates clears local database on configure ([#551](https://github.com/aws-amplify/amplify-ios/pull/551))
* **DataStore/API** Add Emeddable type to `Model` internals, to store schema info for custom types ([#539](https://github.com/aws-amplify/amplify-ios/pull/539) and [#562](https://github.com/aws-amplify/amplify-ios/pull/562)). This bug impacts developers with schemas containing embedded types when using DataStore with sync to cloud enabled or using API with Model classes. To fix this bug, upgrade both Amplify CLI to 4.22.0, and Amplify Libraries to 1.0.2. There is a known incompatibility if only upgrading CLI but not the Library. Then run `amplify codegen models` to regenerate the Model classes. The internal ModelFieldType `.customType` has been replaced with `.embedded(type:)` and `embeddedCollection(of:)`. 
* **Tools** Update Amplify tools script to resolve node correctly when NVM is installed ([#535](https://github.com/aws-amplify/amplify-ios/pull/535))
* **Tools** Update Amplify tools script to resolve min CLI version for codegen changes ([#583](https://github.com/aws-amplify/amplify-ios/pull/583))

### Misc

* **Build** Add common dependency configuration, standardize environment across all modules, podspec source version tag and url ([#538](https://github.com/aws-amplify/amplify-ios/pull/538))
* **Build** Update CoreML podspec with amplify version ([#555](https://github.com/aws-amplify/amplify-ios/pull/555))
* **Build** Fix `pod lib lint` error using local variable definitions in Podspec files ([#557](https://github.com/aws-amplify/amplify-ios/pull/557))
* **Build** Changed the repo's default branch to 'main' ([#579](https://github.com/aws-amplify/amplify-ios/pull/579))
* **Core** Move DataStore Model Schema related classes to Internal directory ([#563](https://github.com/aws-amplify/amplify-ios/pull/563))

## 1.0.1 (2020-06-05)

### Bug Fixes

* **DataStore:** Fixed a DataStore issue where nested associations that were 3 levels or more deep would fail to decode into the Swift models ([#520](https://github.com/aws-amplify/amplify-ios/pull/520))
* **DataStore:** Support all Temporal types in predicates ([#513](https://github.com/aws-amplify/amplify-ios/pull/513))
* **API:** Fixed a problem with the selection set that is generated for a Model containing a connection to another Model ([#509](https://github.com/aws-amplify/amplify-ios/pull/509))
* **API:** Fixed a bug with nil value not updated in GraphQL model value to nil ([#519](https://github.com/aws-amplify/amplify-ios/pull/519))
* **API:** Fixed QueryPredicate to GraphQLValue logic, missing Temporal.DateTime conversion ([#508](https://github.com/aws-amplify/amplify-ios/pull/508))
* **Tools:** Allow Amplify tools to run if the project folder has a space char ([#506](https://github.com/aws-amplify/amplify-ios/pull/506))
* **Tools:** Update Amplify tools script to check for minimum version of amplify-app and amplify cli ([#511](https://github.com/aws-amplify/amplify-ios/pull/511))

### Misc

* Fixed build errors for fresh installation of Amplify pods ([#517](https://github.com/aws-amplify/amplify-ios/pull/517))
* Updated Datastore models for testing. ([#526](https://github.com/aws-amplify/amplify-ios/pull/526/))
* Integration test for Auth ([#497](https://github.com/aws-amplify/amplify-ios/pull/497))

## 1.0.0 (2020-05-26)

### Bug Fixes

* Tools: Add npx to amplify-app and fix typo ([#486](https://github.com/aws-amplify/amplify-ios/issues/486)) ([c7d11a7](https://github.com/aws-amplify/amplify-ios/commit/c7d11a7b1291a2aa588fdcca5bf51e259490d9b5))

### Misc

Misc cleanup, improved test coverage from RC1:

* **API:** Added SocialNote from codegen ([#469](https://github.com/aws-amplify/amplify-ios/issues/469)) ([79c6482](https://github.com/aws-amplify/amplify-ios/commit/79c648264d88683c7b2caa907f46984c811230e6))
* **Auth:** Hub events for signedIn signedOut and sessionExpire ([#457](https://github.com/aws-amplify/amplify-ios/issues/457)) ([38e0513](https://github.com/aws-amplify/amplify-ios/commit/38e0513545b6e5a5127e233ae414f247d68749be))
* **Auth:** Implementation of getCurrentUser api ([#455](https://github.com/aws-amplify/amplify-ios/issues/455)) ([59f6b18](https://github.com/aws-amplify/amplify-ios/commit/59f6b18651f1848d882c92203177981c5f195a9b))
* **Core:** bootstrap Auth configuration before other categories, and fixed analytics integration tests ([#475](https://github.com/aws-amplify/amplify-ios/issues/475)) ([c33bf1b](https://github.com/aws-amplify/amplify-ios/commit/c33bf1b11fb7496227917670dc4b75fc3f10430e))
* **DataStore:** StartSync with Auth ([#471](https://github.com/aws-amplify/amplify-ios/issues/471)) ([7cab76f](https://github.com/aws-amplify/amplify-ios/commit/7cab76fd785d7cd519280a912f8ab70fda87dc12))

## 1.0.0-rc.1 (2020-05-21)

### ⚠ BREAKING CHANGES

* The `AsyncEvent` type has been removed. Listeners to most Amplify APIs will now be invoked with standard Swift `Result`s. APIs that deliver multiple values over time also include an "in process" listener.
* **Auth** category error type is changed to `AuthError`. Current implementations that make use of `AmplifyAuthError` will break with build time error.
  * As part of this work, we deleted `AuthError` in the **Storage** category.

### Features

* Added **Auth** category
* Added AuthRule decorator to allow for granular ownership control of GraphQL models
* Miscellaneous improvements to API semantics and ergonomics throughout
* Increased test coverage throughout
* **Datastore** now exposes configurable syncMaxRecords and syncPageSize ([#388](https://github.com/aws-amplify/amplify-ios/issues/388)) ([ca15e88](https://github.com/aws-amplify/amplify-ios/commit/ca15e881d7479020053b0db15a844cd2584b1db1))

* [API] Merge non-GraphQL spec error fields into GraphQLError.extensions ([#401](https://github.com/aws-amplify/amplify-ios/issues/401)) ([b87811c](https://github.com/aws-amplify/amplify-ios/commit/b87811c5d1230c4d1f0a809192266a18bb3d7949))
* Using config to decide base query or delta query ([#386](https://github.com/aws-amplify/amplify-ios/issues/386)) ([b02c3b7](https://github.com/aws-amplify/amplify-ios/commit/b02c3b7fc6400d558ab9e0213eda404ebb3bae37))

### Bug Fixes

* **amplify-tools:**
  * Change the tools script to comply with amplify-app changes ([#445](https://github.com/aws-amplify/amplify-ios/issues/445)) ([67412ca](https://github.com/aws-amplify/amplify-ios/commit/67412ca1513057f7f6e473f37ec9b89230642655))
  * Fix escaped json in shell script ([#452](https://github.com/aws-amplify/amplify-ios/issues/452)) ([5b4b9d2](https://github.com/aws-amplify/amplify-ios/commit/5b4b9d2f802eb299f3399c9cf27d435cb919815b))
* **DataStore:**
  * Only start the remote sync engine if we have awsapiplugin ([#442](https://github.com/aws-amplify/amplify-ios/issues/442)) ([532058a](https://github.com/aws-amplify/amplify-ios/commit/532058a5052bc3a0a5565595708964c063b3c28a))
  * Bug where subscription connections happen at the same time ([#389](https://github.com/aws-amplify/amplify-ios/issues/389)) ([81e6111](https://github.com/aws-amplify/amplify-ios/commit/81e61116739aefa6b55b29e7e059edc0e51b5b94))
  * Clear inProcess state on startup of outgoing mutation queue ([#391](https://github.com/aws-amplify/amplify-ios/issues/391)) ([352680b](https://github.com/aws-amplify/amplify-ios/commit/352680bd95c2c6c38d8263e870658f96bef9172a))
  * Mark outgoing mutation as inProcess if nextEventPromise exists ([#392](https://github.com/aws-amplify/amplify-ios/issues/392)) ([3986cf5](https://github.com/aws-amplify/amplify-ios/commit/3986cf57bd042acdb2eb66bdce503616df05ed5f))

## 0.11.0

### New Features

- **Predictions**
  - Added the ability to transcribe text for both online and offline use cases. PR [#290](https://github.com/aws-amplify/amplify-ios/pull/290)
- **API**
  - Add GraphQLDocument builder classes for constructing Model-based GraphQL APIs. PR [#309](https://github.com/aws-amplify/amplify-ios/pull/309)
  - Add support for REST API with Cognito User Pools. PR [#312](https://github.com/aws-amplify/amplify-ios/pull/312)
- **DataStore**
  - DataStore.save() now supports passing in condition. PR [#355](https://github.com/aws-amplify/amplify-ios/pull/355)
  - Added reachability and retryability to remote sync engine. PRs [#321](https://github.com/aws-amplify/amplify-ios/pull/321) [#322](https://github.com/aws-amplify/amplify-ios/pull/322) [#323](https://github.com/aws-amplify/amplify-ios/pull/323) [#324](https://github.com/aws-amplify/amplify-ios/pull/324)
  - Datastore.delete(modelType) with predicate. PR [#346](https://github.com/aws-amplify/amplify-ios/pull/346)
  - Datastore.clear() async to remove local datastore. PR [#353](https://github.com/aws-amplify/amplify-ios/pull/353)
  - Add pagination support to DataStore. PR [#365](https://github.com/aws-amplify/amplify-ios/pull/365)
  - Add support for Enum and non-model types. PR [334](https://github.com/aws-amplify/amplify-ios/pull/334) Issues [#111](https://github.com/aws-amplify/amplify-ios/issues/111) [#240](https://github.com/aws-amplify/amplify-ios/issues/240) [#246](https://github.com/aws-amplify/amplify-ios/issues/246) [#318](https://github.com/aws-amplify/amplify-ios/issues/318) [#314](https://github.com/aws-amplify/amplify-ios/issues/314)

### Bug Fixes

- **DataStore**
  - Fix out of bounds case when retry handler >= 57. PR [#338](https://github.com/aws-amplify/amplify-ios/pull/338)

### Misc. Updates

- **General**
  - AWS iOS SDK Dependency upgrade to 2.13.x. PR [#360](https://github.com/aws-amplify/amplify-ios/pull/360)

- **API**
  - Migrate APIPlugin's websocket provider to use AppSyncRealTimeClient. PRs [#330](https://github.com/aws-amplify/amplify-ios/pull/330), [#341](https://github.com/aws-amplify/amplify-ios/pull/341), [#352](https://github.com/aws-amplify/amplify-ios/pull/352)

## 0.10.0

### New Features

- Adding amplify specific user agent, revival of PR#166 ([#271](https://github.com/aws-amplify/amplify-ios/issues/271))

### Updates

- **API**
  - Reprovision API Integration test backends ([#250](https://github.com/aws-amplify/amplify-ios/issues/250))
  - Remove dependency on ModelRegistry for adding syncable fields to selection set. ([#252](https://github.com/aws-amplify/amplify-ios/issues/252))
- **DataStore**
  - Adding unit tests for AWSMutationDatabaseAdapterTests ([#231](https://github.com/aws-amplify/amplify-ios/issues/231))
  - Initial sync startup/3-way merge ([#238](https://github.com/aws-amplify/amplify-ios/issues/238))
  - Integrate retryability for outgoing mutation queue ([#266](https://github.com/aws-amplify/amplify-ios/issues/266))
- **Storage**
  - Reprovision Storage Integration test backend ([#256](https://github.com/aws-amplify/amplify-ios/issues/256))

## 0.9.0

Initial release! Includes Core features, plus support for these categories:

- Analytics
- API
- DataStore
- Predictions
- Storage
