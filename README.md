## Amplify for iOS (Preview)
<img src="https://s3.amazonaws.com/aws-mobile-hub-images/aws-amplify-logo.png" alt="AWS Amplify" width="550" >
AWS Amplify provides a declarative and easy-to-use interface across different categories of cloud operations. AWS Amplify goes well with any JavaScript based frontend workflow, and React Native for mobile developers.

Our default implementation works with Amazon Web Services (AWS), but AWS Amplify is designed to be open and pluggable for any custom backend or service.

- **API Documentation**
  https://aws-amplify.github.io/docs/ios/start

## Features/APIs
*Note: Amplify docs are still being updated and will go live by EOW. The below links will take you to the SDK documentation currently.

- [**Analytics**](https://aws-amplify.github.io/docs/ios/analytics): Easily collect analytics data for your app. Analytics data includes user sessions and other custom events that you want to track in your app.
- [**API**](https://aws-amplify.github.io/docs/ios/api): Provides a simple solution when making HTTP requests. It provides an automatic, lightweight signing process which complies with AWS Signature Version 4.
- [**GraphQL Client**](https://aws.github.io/aws-amplify/media/api_guide#configuration-for-graphql-server): Interact with your GraphQL server or AWS AppSync API with an easy-to-use & configured GraphQL client.
- [**Storage**](https://aws-amplify.github.io/docs/ios/storage): Provides a simple mechanism for managing user content for your app in public, protected or private storage buckets.
- [**Predictions**](https://aws-amplify.github.io/docs/ios/predictions): Provides a solution for using AI and ML cloud services to enhance your application.

All services and features not listed above are supported via the [iOS SDK](https://github.com/aws-amplify/aws-sdk-ios) or if supported by a category can be accessed via the Escape Hatch like below:

``` swift
let rekognitionService = Amplify.Predictions.getEscapeHatch(key: .rekognition) as! AWSRekognition
let request = rekognitionService.AWSRekognitionCreateCollectionRequest()
rekognitionService.createCollection(request)
```

## Platform Support

Amplify supports iOS 11 and above and iOS 13 for certain categories such as Predictions. There are currently no plans to support Amplify on WatchOS, tvOS, or MacOS.

## License

This library is licensed under the Apache 2.0 License. 

## Installation

Amplify requires Xcode 11 or higher to build.

### CocoaPods

Coming soon, will be live by December 6. You can use manually in the mean time per instructions under Development Pods below.

### Carthage

Coming soon, will be live by December 6. You can use manually in the mean time per instructions under Development Pods below.

### Development Pods

You can manually install the library by cloning this repo and creating a Podfile that references your local clone of it like below:

``` ruby
  pod 'Amplify', :path => '~/Projects/Amplify/amplify-ios'
  pod 'AWSPluginsCore', :path => '~/Projects/Amplify/amplify-ios'
  pod 'CoreMLPredictionsPlugin', :path => '~/Projects/Amplify/amplify-ios'
  pod 'AmplifyPlugins/AWSPredictionsPlugin', :path => '~/Projects/Amplify/amplify-ios'
```
You also need to go to your target project by clicking the top level project in Xcode and then clicking under Targets on your project. Then head to Build Phases -> Link Binary with Libraries -> Add Amplify Frameworks and any others you need for the category or categories you would like to use.
