# Changelog
## Unreleased
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
