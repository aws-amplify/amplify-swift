# Amplify for iOS - CHANGELOG

A declarative library for application development using cloud services.

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
