## Amplify for iOS (Preview)
<img src="https://s3.amazonaws.com/aws-mobile-hub-images/aws-amplify-logo.png" alt="AWS Amplify" width="550" >
AWS Amplify provides a declarative and easy-to-use interface across different categories of cloud operations. AWS Amplify goes well with any JavaScript based frontend workflow, and React Native for mobile developers.

Our default implementation works with Amazon Web Services (AWS), but AWS Amplify is designed to be open and pluggable for any custom backend or service.

- **API Documentation**
  https://aws-amplify.github.io/docs/ios/start

## Features/APIs

- [**Analytics**](https://aws-amplify.github.io/docs/ios/analytics): Easily collect analytics data for your app. Analytics data includes user sessions and other custom events that you want to track in your app.
- [**API**](https://aws-amplify.github.io/docs/ios/api): Interact with your AWS AppSync API or make HTTP requests to your API Gateway endpoint with Amplify API. It provides a GraphQL client interface to use with Amplify Tool's model generation and automatic signing process to authenticate your requests.
- [**Storage**](https://aws-amplify.github.io/docs/ios/storage): Provides a simple mechanism for managing user content for your app in guest, protected or private storage buckets.
- [**Predictions**](https://aws-amplify.github.io/docs/ios/predictions): Provides a solution for using AI and ML cloud services to enhance your application.

All services and features not listed above are supported via the [iOS SDK](https://aws-amplify.github.io/docs/sdk/ios/start) or if supported by a category can be accessed via the Escape Hatch like below:`

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
  pod 'Amplify', :path => '~/amplify-ios'
  pod 'AWSPluginsCore', :path => '~/amplify-ios'
  pod 'CoreMLPredictionsPlugin', :path => '~/amplify-ios'
  pod 'AWSPredictionsPlugin', :path => '~/amplify-ios'
  pod 'AmplifyPlugins/AWSAPIPlugin', :path => '~/amplify-ios'
```

Then, install the dependencies:
```
pod install
```

Open your project using ./YOUR-PROJECT-NAME.xcworkspace file. Remember to always use ./YOUR-PROJECT-NAME.xcworkspace to open your Xcode project from now on.
