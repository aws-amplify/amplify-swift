## Amplify for iOS
<img src="https://s3.amazonaws.com/aws-mobile-hub-images/aws-amplify-logo.png" alt="AWS Amplify" width="550" >
AWS Amplify provides a declarative and easy-to-use interface across different categories of cloud operations. AWS Amplify goes well with any JavaScript based frontend workflow, and React Native for mobile developers.

Our default implementation works with Amazon Web Services (AWS), but AWS Amplify is designed to be open and pluggable for any custom backend or service.

- **API Documentation**
  https://docs.amplify.aws/start/q/integration/ios

[![Cocoapods](https://img.shields.io/cocoapods/v/Amplify)](https://cocoapods.org/pods/Amplify)
[![CircleCI](https://circleci.com/gh/aws-amplify/amplify-ios.svg?style=shield)](https://circleci.com/gh/aws-amplify/amplify-ios)
[![Discord](https://img.shields.io/discord/308323056592486420?logo=discord)](https://discord.gg/jWVbPfC)

## Features/APIs

- [Analytics](https://docs.amplify.aws/lib/analytics/getting-started/q/platform/ios) - for logging metrics and understanding your users.
- [API (GraphQL)](https://docs.amplify.aws/lib/graphqlapi/getting-started/q/platform/ios) - for adding a GraphQL endpoint to your app.
- [API (REST)](https://docs.amplify.aws/lib/restapi/getting-started/q/platform/ios) - for adding a REST endpoint to your app.
- [Authentication](https://docs.amplify.aws/lib/auth/getting-started/q/platform/ios) - for managing your users.
- [DataStore](https://docs.amplify.aws/lib/datastore/getting-started/q/platform/ios) - for making it easier to program for a distributed data store for offline and online scenarios.
- [Predictions](https://docs.amplify.aws/lib/predictions/getting-started/q/platform/ios) - to detect text, images, and more!
- [Storage](https://docs.amplify.aws/lib/storage/getting-started/q/platform/ios) - store complex objects like pictures and videos to the cloud.

All services and features not listed above are supported via the [iOS SDK](https://docs.amplify.aws/sdk/q/platform/ios) or if supported by a category can be accessed via the Escape Hatch like below:`

```swift
let rekognitionService = Amplify.Predictions.getEscapeHatch(key: .rekognition) as! AWSRekognition
let request = rekognitionService.AWSRekognitionCreateCollectionRequest()
rekognitionService.createCollection(request)
```

## Platform Support

Amplify supports iOS 11 and above and iOS 13 for certain categories such as Predictions. There are currently no plans to support Amplify on WatchOS, tvOS, or MacOS.

## License

This library is licensed under the Apache 2.0 License. 

## Installation

Amplify requires Xcode 11.4 or higher to build.

### CocoaPods

| :information_source: For more detailed instructions, follow the getting started guides in our [documentation site](https://docs.amplify.aws/lib/q/platform/ios)   |
|-------------------------------------------------|

1. Amplify for iOS is available through [CocoaPods](http://cocoapods.org). If you have not installed CocoaPods, install CocoaPods by running the command:
    ```
    $ gem install cocoapods
    $ pod setup
    ```

    Depending on your system settings, you may have to use `sudo` for installing `cocoapods` as follows:
    
    ```
    $ sudo gem install cocoapods
    $ pod setup
    ```

2. In your project directory (the directory where your `*.xcodeproj` file is), type `pod init` and open the Podfile that was created. Add the `Amplify` pod and any plugins you would like to use. Below is an example of what a podfile might look like if you were going to use the Predictions plugin.
    ```ruby
    source 'https://github.com/CocoaPods/Specs.git'
    
    platform :ios, '13.0'
    use_frameworks!

    target :'YourTarget' do
        pod 'Amplify'
        pod 'AmplifyPlugins/AWSCognitoAuthPlugin'
        pod 'AWSPredictionsPlugin'
        pod 'CoreMLPredictionsPlugin'
    end
    ```
        
3. Then run the following command:
    ```
    $ pod install
    ```
4. Open up `*.xcworkspace` with Xcode and start using Amplify.

    ![image](readme-images/cocoapods-setup-02.png?raw=true)

    **Note**: Do **NOT** use `*.xcodeproj`. If you open up a project file instead of a workspace, you will receive an error.

### Swift Package Manager (SPM)

Support for SPM coming soon. Follow [#90](https://github.com/aws-amplify/amplify-ios/issues/90) for updates.

### Development Pods

You can manually install the library by cloning this repo and creating a Podfile that references your local clone of it like below:

```ruby
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

## Reporting Bugs/Feature Requests

[![Open Bugs](https://img.shields.io/github/issues/aws-amplify/amplify-ios/bug?color=d73a4a&label=bugs)](https://github.com/aws-amplify/amplify-ios/issues?q=is%3Aissue+is%3Aopen+label%3Abug)
[![Open Questions](https://img.shields.io/github/issues/aws-amplify/amplify-ios/usage%20question?color=558dfd&label=questions)](https://github.com/aws-amplify/amplify-ios/issues?q=is%3Aissue+label%3A%22usage+question%22+is%3Aopen)
[![Feature Requests](https://img.shields.io/github/issues/aws-amplify/amplify-ios/feature%20request?color=ff9001&label=feature%20requests)](https://github.com/aws-amplify/amplify-ios/issues?q=is%3Aissue+label%3A%22feature+request%22+is%3Aopen+)
[![Closed Issues](https://img.shields.io/github/issues-closed/aws-amplify/amplify-ios?color=%2325CC00)](https://github.com/aws-amplify/amplify-ios/issues?q=is%3Aissue+is%3Aclosed+)

We welcome you to use the GitHub issue tracker to report bugs or suggest features.

When filing an issue, please check [existing open](https://github.com/aws-amplify/amplify-ios/issues), or [recently closed](https://github.com/aws-amplify/amplify-ios/issues?utf8=%E2%9C%93&q=is%3Aissue%20is%3Aclosed%20), issues to make sure somebody else hasn't already
reported the issue. Please try to include as much information as you can. Details like these are incredibly useful:

* Expected behavior and observed behavior
* A reproducible test case or series of steps
* The version of our code being used
* Any modifications you've made relevant to the bug
* Anything custom about your environment or deployment

## Open Source Contributions

We welcome any and all contributions from the community! Make sure you read through our contribution guide [here](./CONTRIBUTING.md) before submitting any PR's. Thanks! <3
