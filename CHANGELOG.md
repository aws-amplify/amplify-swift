# Amplify for iOS - CHANGELOG

A declarative library for application development using cloud services.

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
