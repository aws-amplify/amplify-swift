## Amplify for iOS (Developer Preview)
<img src="https://s3.amazonaws.com/aws-mobile-hub-images/aws-amplify-logo.png" alt="AWS Amplify" width="550" >

AWS Amplify provides a declarative and easy-to-use interface across different categories of cloud operations. Our default implementation works with Amazon Web Services (AWS), but AWS Amplify is designed to be open and pluggable for any custom backend or service.

The Developer Preview of the Amplify iOS Library is now exclusively using Swift and provides developers the ability to add cloud-based Auth, Storage, Data, and APIs to their apps. With this version, Swift developers will be able to debug and contribute to the underlying open-source codebase completely in Swift. We plan to incrementally add more Amplify features including Swift-based language features like structured concurrency.

This developer preview version of Amplify iOS is layered on the [AWS SDK for Swift](https://aws.amazon.com/sdk-for-swift/), which was released as Developer Preview last year. This allows for access to the AWS SDK for Swift for a breadth of service-centric APIs.

You can also quickly get started by using our [Photo Sharing Sample App](https://github.com/aws-amplify/amplify-ios-samples/tree/dev-preview).

We deeply appreciate your feedback on this Developer Preview as we work towards our General Availability launch: [GitHub Discussion](https://github.com/aws-amplify/amplify-ios/discussions/categories/developer-preview) or [File a Bug Report](https://github.com/aws-amplify/amplify-ios/issues/new/choose).

- **API Documentation**
  https://docs.amplify.aws/start/q/integration/ios

[![CircleCI](https://circleci.com/gh/aws-amplify/amplify-ios.svg?style=shield)](https://circleci.com/gh/aws-amplify/amplify-ios)
[![Discord](https://img.shields.io/discord/308323056592486420?logo=discord)](https://discord.gg/jWVbPfC)

## Features/APIs

- [API (GraphQL)](https://docs.amplify.aws/lib/graphqlapi/getting-started/q/platform/ios) - for adding a GraphQL endpoint to your app.
- [API (REST)](https://docs.amplify.aws/lib/restapi/getting-started/q/platform/ios) - for adding a REST endpoint to your app.
- [Authentication](https://docs.amplify.aws/lib/auth/getting-started/q/platform/ios) - for managing your users.
   - _Note: Authentication category only supports **Sign Up**, **Sign In**, **Sign Out** and **Fetch Auth Session** API's._
- [DataStore](https://docs.amplify.aws/lib/datastore/getting-started/q/platform/ios) - for making it easier to program for a distributed data store for offline and online scenarios.
- [Storage](https://docs.amplify.aws/lib/storage/getting-started/q/platform/ios) - store complex objects like pictures and videos to the cloud.


All services and features not listed above are supported via the [Swift SDK](https://github.com/awslabs/aws-sdk-swift) or if supported by a category can be accessed via the Escape Hatch like below:

```swift
guard let plugin = try Amplify.Storage.getPlugin(for: "awsS3StoragePlugin") as? AWSS3StoragePlugin else {
    print("Unable to to cast to AWSS3StoragePlugin")
    return
}

let awsS3 = plugin.getEscapeHatch()
let input: HeadBucketInput = HeadBucketInput()
let task = awsS3.headBucket(input: input) { result in
    switch result {
    case .success(let response):
        print(response)
    case .failure(let error):
        print(error)
    }
}
```

## Platform Support

Amplify supports iOS 13 and above. There are currently no plans to support Amplify on watchOS, tvOS, or macOS.

## License

This library is licensed under the Apache 2.0 License. 

## Installation

Amplify requires Xcode 11.4 or higher to build.

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
    - Auth: **AWSCognitoAuthPlugin**
    - DataStore: **AWSDataStorePlugin**
    - Storage: **AWSS3StoragePlugin**

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

We welcome any and all contributions from the community! Make sure you read through our contribution guide [here](./CONTRIBUTING.md) before submitting any PR's. Thanks! ♥️
