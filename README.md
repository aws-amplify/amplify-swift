## Amplify for iOS
<img src="https://s3.amazonaws.com/aws-mobile-hub-images/aws-amplify-logo.png" alt="AWS Amplify" width="550" >
AWS Amplify provides a declarative and easy-to-use interface across different categories of cloud operations. AWS Amplify goes well with any JavaScript based frontend workflow, and React Native for mobile developers.

Our default implementation works with Amazon Web Services (AWS), but AWS Amplify is designed to be open and pluggable for any custom backend or service.

[**API Documentation**](https://aws-amplify.github.io/amplify-ios/docs/)

[**Getting Started Guide**](https://docs.amplify.aws/start/q/integration/ios)

[![Cocoapods](https://img.shields.io/cocoapods/v/Amplify)](https://cocoapods.org/pods/Amplify)
[![CircleCI](https://circleci.com/gh/aws-amplify/amplify-ios.svg?style=shield)](https://circleci.com/gh/aws-amplify/amplify-ios)
[![Discord](https://img.shields.io/discord/308323056592486420?logo=discord)](https://discord.gg/jWVbPfC)

## Features/APIs

- [Analytics](https://docs.amplify.aws/lib/analytics/getting-started/q/platform/ios) - for logging metrics and understanding your users.
- [API (GraphQL)](https://docs.amplify.aws/lib/graphqlapi/getting-started/q/platform/ios) - for adding a GraphQL endpoint to your app.
- [API (REST)](https://docs.amplify.aws/lib/restapi/getting-started/q/platform/ios) - for adding a REST endpoint to your app.
- [Authentication](https://docs.amplify.aws/lib/auth/getting-started/q/platform/ios) - for managing your users.
- [DataStore](https://docs.amplify.aws/lib/datastore/getting-started/q/platform/ios) - for making it easier to program for a distributed data store for offline and online scenarios.
- [Geo](https://docs.amplify.aws/lib/geo/getting-started/q/platform/ios) - for adding location-based capabilities to your app.
- [Predictions](https://docs.amplify.aws/lib/predictions/getting-started/q/platform/ios) - to detect text, images, and more!
- [Storage](https://docs.amplify.aws/lib/storage/getting-started/q/platform/ios) - store complex objects like pictures and videos to the cloud.

All services and features not listed above are supported via the [iOS SDK](https://docs.amplify.aws/sdk/q/platform/ios) or if supported by a category can be accessed via the Escape Hatch like below:

```swift
guard let predictionsPlugin = try Amplify.Predictions.getPlugin(for: "awsPredictionsPlugin") as? AWSPredictionsPlugin else {
    print("Unable to cast to AWSPredictionsPlugin")
    return
}

guard let rekognitionService = predictionsPlugin.getEscapeHatch(key: .rekognition) as? AWSRekognition else {
    print("Unable to get AWSRekognition")
    return
}

let request = AWSRekognitionCreateCollectionRequest()
if let request = request {
    rekognitionService.createCollection(request)
}
```

## Platform Support

Amplify supports iOS 11 and above and iOS 13 for certain categories such as Predictions and Geo. There are currently no plans to support Amplify on WatchOS, tvOS, or MacOS.

## License

This library is licensed under the Apache 2.0 License. 

## Installation

Amplify requires Xcode 12 or higher to build.

| For more detailed instructions, follow the getting started guides in our [documentation site](https://docs.amplify.aws/lib/q/platform/ios)   |
|-------------------------------------------------|

### Swift Package Manager

1. Swift Package Manager is distributed with Xcode. To start adding the Amplify Libraries to your iOS project, open your project in Xcode and select **File > Swift Packages > Add Package Dependency**.

    ![Add package dependency](readme-images/spm-setup-01-add-package-dependency.png)

1. Enter the Amplify iOS GitHub repo URL (`https://github.com/aws-amplify/amplify-ios`) into the search bar and click **Next**.

    ![Search for repo](readme-images/spm-setup-02-search-amplify-repo.png)

1. You'll see the Amplify iOS repository rules for which version of Amplify you want Swift Package Manager to install. Choose the first rule, **Version**, as it will use the latest compatible version of the dependency that can be detected from the `main` branch, then click **Next**.

    ![Dependency version options](readme-images/spm-setup-03-dependency-version-options.png)

1. Choose which of the libraries you want added to your project. Always select the **Amplify** library. The "Plugin" to install depends on which categories you are using:

    - API: **AWSAPIPlugin**
    - Analytics: **AWSPinpointAnalyticsPlugin**
    - Auth: **AWSCognitoAuthPlugin**
    - DataStore: **AWSDataStorePlugin**
    - Storage: **AWSS3StoragePlugin**

      _Note: AWSPredictionsPlugin is not currently supported through Swift Package Manager due to different minimum iOS version requirements. Support for this will eventually be added._

    ![Select dependencies](readme-images/spm-setup-04-select-dependencies.png)

    Select all that are appropriate, then click **Finish**.

    You can always go back and modify which SPM packages are included in your project by opening the Swift Packages tab for your project: Click on the Project file in the Xcode navigator, then click on your project's icon, then select the **Swift Packages** tab.

1. In your app code, explicitly import a plugin when you need to add a plugin to Amplify, access plugin options, or access a category escape hatch.

    ```swift
    import Amplify
    import AWSAPIPlugin
    import AWSDataStorePlugin

    // ... later

    func initializeAmplify() {
        do {
            try Amplify.add(AWSAPIPlugin())
            // and so on ...
        } catch {
            assert(false, "Error initializing Amplify: \(error)")
        }
    }
    ```

    If you're just accessing Amplify category APIs (e.g., `Auth.signIn()` or `Storage.uploadFile()`), you only need to import Amplify:

    ```swift
    import Amplify

    // ... later

    func doUpload() {
        Amplify.Storage.uploadFile(...)
    }
    ```

### CocoaPods

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

1. In your project directory (the directory where your `*.xcodeproj` file is), type `pod init` and open the Podfile that was created. Add the `Amplify` pod and any plugins you would like to use. Below is an example of what a podfile might look like if you were going to use the Predictions plugin.
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
        
1. Then run the following command:
    ```
    $ pod install
    ```
1. Open up `*.xcworkspace` with Xcode and start using Amplify.

    ![image](readme-images/cocoapods-setup-02.png?raw=true)

    **Note**: Do **NOT** use `*.xcodeproj`. If you open up a project file instead of a workspace, you will receive an error.

1. In your app code, import `AmplifyPlugins` when you need to add a plugin to Amplify, access plugin options, or access a category escape hatch.

    ```swift
    import Amplify
    import AmplifyPlugins

    // ... later

    func initializeAmplify() {
        do {
            try Amplify.add(AWSAPIPlugin())
            // and so on ...
        } catch {
            assert(false, "Error initializing Amplify: \(error)")
        }
    }
    ```

    If you're just accessing Amplify category APIs (e.g., `Auth.signIn()` or `Storage.uploadFile()`), you only need to import Amplify:

    ```swift
    import Amplify

    // ... later

    func doUpload() {
        Amplify.Storage.uploadFile(...)
    }
    ```

**Development Pods**

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
[![Open Questions](https://img.shields.io/github/issues/aws-amplify/amplify-ios/usage%20question?color=558dfd&label=questions)](https://github.com/aws-amplify/amplify-ios/issues?q=is%3Aissue+label%3A%22question%22+is%3Aopen+)
[![Feature Requests](https://img.shields.io/github/issues/aws-amplify/amplify-ios/feature%20request?color=ff9001&label=feature%20requests)](https://github.com/aws-amplify/amplify-ios/issues?q=is%3Aissue+label%3A%22feature-request%22+is%3Aopen+)
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

We welcome any and all contributions from the community! Make sure you read through our contribution guide [here](./CONTRIBUTING.md) before submitting any PR's. Thanks! ♥️
