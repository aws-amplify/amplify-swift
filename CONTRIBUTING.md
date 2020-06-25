# Amplify iOS Contributing Guide

Thank you for your interest in contributing to our project! <3 Whether it's a bug report, new feature, correction, or additional documentation, we greatly value feedback and contributions from our community. The following is our contribution guide, which we hope you will read through carefully prior to submitting a pull-request (PR) or issue. In the event that our guide is not up to date, feel free to let us know by opening an issue (or even better, submit a PR with your proposed corrections ;)).

- [History & Ethos](#our-history-and-ethos)
  - [Our Design](#our-design)
- [Getting Started](#getting-started)
- [Testing](#testing)
- [Tools](#tools)
- [Debugging](#debugging)
  - [Running Cocoapods Locally](#running-cocoapods-locally)
- [Pull Requests](#pull-requests)
  - [Pull Request Checklist](#pull-request-checklist)
  - [Step 1: Open Issue](#step-1-open-issue)
  - [Step 2: Design (optional)](#step-2-design-optional)
  - [Step 3: Fork The Repo](#step-3-fork-the-repo)
  - [Step 4: Work your Magic](#step-3-work-your-magic)
  - [Step 5: Commit](#step-4-commit)
  - [Step 6: Pull Request](#step-5-pull-request)
  - [Step 7: Merge](#step-6-merge)
- [Troubleshooting](#troubleshooting)
- [Related Repositories](#related-repositories)
- [Finding Contributions](#finding-contributions-to-work-on)
- [Code of Conduct](#code-of-conduct)
- [Security Issue Notifications](#security-issue-notifications)
- [Licensing](#licensing)

For a brief history and our ethos/design philosophy around the Amplify project please refer to this [document](/ETHOS.md).

## Getting Started

To get started with the Amplify Framework for iOS, first make sure you have the latest version of Xcode installed as well as cocoapods. You can install cocoapods by simply running:

```
sudo gem install cocoapods
```

Then make sure you fork the project first and then clone it by running:

```
git clone git@github.com:YOURGITHUBUSERNAME/amplify-ios.git
```
GitHub provides additional documentation on [forking a repository](https://help.github.com/articles/fork-a-repo/).

The Amplify iOS framework has been divided into multiple Xcode projects. You can find any of the catgory specific ones under `AmplifyPlugins` in their specific category folder:

- Core - Amplify.xcworkspace - Includes high level category interfaces and shared interfaces. Shared components including Hub.
- API - Includes the plugin with implementations for the API category. 
- Analytics - Includes the plugin with implementations for the analytics category.
- DataStore - Includes the plugins with the implementations for the datastore category
- Predictions - Includes 2 plugins (AWS and CoreML) with the implementations for the predictions category.
- Storage - Includes the plugin with the implementation for the storage category.

Prior to making changes, you will need to run `pod install` in the directory in which you intend to make changes. For example, if you wanted to add another API to the Storage category, you might start by running `pod install` at the root of the project. Then, open the Amplify Core workspace and enter the Storage folder, with the commands below:

```
cd amplify-ios
pod install
xed .
```

After you add the new API to the storage category, you'll want to support the API in a plugin. To do so:

```
cd amplify-ios/AmplifyPlugins/Storage
pod install
xed .
```
## Testing

Each plugin has its own set of unit and integration tests. Make sure to run the unit tests from the plugin and relevant integration tests from the other test targets in the workspace to ensure there is no regression and add new tests where needed, to cover the changes you are making. 

The test targets are under each workspace containing the plugin are named "'PluginName'E2ETests", "'PluginName'IntegrationTests", and "'PluginName'FunctionalTests". First install [Amplify CLI](https://github.com/aws-amplify/amplify-cli) and then follow the instructions in the README.md at the root of the test target to provision and set up the backend to run the integration tests.

## Tools

[Xcode](https://developer.apple.com/xcode/) and [Cocoapods](https://guides.cocoapods.org/using/getting-started.html) are used for all build and dependency management.

## Debugging

### Running Cocoapods Locally

Framework development is quite different from typical app development when it comes to debugging and being able to test your code. First you will want to create a new app that uses the pods you changed. For instance, if you changed something in the `Storage` category to test to see if it works, you will need to create a new app and run `pod init` and edit the `Podfile` to use the local version of Amplify that you are building on. This is done by editing the `Podfile` of the new application to take a path to the pod instead of a version number like below:

```ruby

target 'MySampleApp' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  # with :path I can direct my project to use a local path for the pod
  pod 'Amplify', :path => '~/Projects/amplify-ios'      # 
  pod 'AmplifyPlugins/AWSS3StoragePlugin', :path => '~/Projects/amplify-ios'
  pod 'AWSPluginsCore', :path => '~/Projects/amplify-ios'           
  
end
```
Then you want to run `pod update` at the root of your sample app to make sure it is using the local version of the pods. When you open the workspace, under the Pods project, the you'll see a section call Development Pods. This where those local pods were installed and if you want to change code here to debug, it will change in the other repo, just make sure you clean and re-build before testing your code again.

## Pull Requests

### Pull Request Checklist
- Testing
    - Unit test added or updated
    - Integration test added or updated
- Changelog
    - Update Changelog with your updates in accordance with our pattern under the new version. Example below:

    ```markdown
    ## Unreleased
      - Please place a note with your updates HERE. :)
    ## 2.xx.x

    ### Bug Fixes

    ### Misc. Updates

    ```

### Step 1: Open Issue

If there isn't one already, open an issue describing what you intend to contribute. It's useful to communicate in advance, because sometimes, someone is already working in this space. So, maybe it's worth collaborating with them instead of duplicating the efforts.

### Step 2: Design

In some cases, it is useful and mandatory to seek for feedback on the design of your planned implementation. This is useful when you plan a breaking change or large feature, or you want advice on what would be the best path forward.

The GitHub issue is sufficient for such discussions, and can be sufficient to get clarity on what you plan to do. Make sure you tag the Amplify Native team using @aws-amplify/amplify-native so we can help guide you.

### Step 3: Fork the Repo

First, create a fork of amplify-ios. Clone it, and make changes to this fork.

```
git clone git@github.com:GITHUBUSERNAME/aws-sdk-ios.git 
# change your GITHUBUSERNAME to your Github username before running this command.
```

### Step 4: Work your magic

Work your magic. Here are some guidelines:

- Coding style (abbreviated):
    - In general, follow the style of the code around you
    - 4 space indentation
    - 100 characters wide
    - Every change requires a new or updated unit test/integ test
    - If you change customer facing APIs, make sure to update the documentation above the interface and include a reason for the breaking change in your PR comments
    - Try to maintain a single feature/bugfix per pull request. It's okay to introduce a little bit of housekeeping changes along the way, but don't conflate multiple features. Eventually all these are going to go into a single commit, so you can use that to frame your scope.

### Step 5: Commit

Create a commit with the proposed change changes:

- Commit message should describe motivation. Think about your code reviewers and what information they need in order to understand what you did. If it's a big commit (hopefully not), try to provide some good entry points so it will be easier to follow.

### Step 6: Pull Request

- Push your changes to your GitHub fork
- Submit a Pull Requests on the amplify-ios repo to the `main` branch and add the Amplify Native team using @aws-amplify/amplify-native so we can approve/provide feedback.
- The title of your PR must be descriptive to the specific change.
- No period at the end of the title.
- Pull Request message should indicate which issues are fixed: `fixes #<issue>` or `closes #<issue>`.
- PR messaged should include shout out to collaborators.
- If not obvious (i.e. from unit tests), describe how you verified that your change works.
- If this PR includes breaking changes, they must be listed at the top of the changelog as described above in the Pull Request Checklist.
- Discuss review comments and iterate until you get at least one “Approve”. When iterating, push new commits to the same branch. 
- Usually all these are going to be squashed when you merge to main.
- Make sure to update the PR title/description if things change. 
- Rebase with the `main` branch if it has commits ahead of your fork.

### Step 7: Merge
Once your PR has been approved and tested, we will merge it into `main` for you and barring any unforeseen circumstances, your changes will be released in our next version. Yay!! 

## Troubleshooting

Some build issues can be solved by [removing your derived data](https://iosdevcenters.blogspot.com/2015/12/how-to-delete-derived-data-and-clean.html) and doing a clean and build. For any other serious build issues, open a new issue or see if there is one existing that may have a fix on it.

## Related Repositories

This project is part of the Amplify Framework, which runs on Android,
iOS, and numerous JavaScript-based web platforms.

1. [AWS Amplify for iOS](https://github.com/aws-amplify/amplify-ios)
2. [AWS Amplify for JavaScript](https://github.com/aws-amplify/amplify-js)

AWS Amplify plugins are built on top of the AWS SDKs. AWS SDKs are a
toolkit for interacting with AWS backend resources.

1. [AWS SDK for Android](https://github.com/aws-amplify/aws-sdk-android)
2. [AWS SDK for iOS](https://github.com/aws-amplify/aws-sdk-ios)
3. [AWS SDK for JavaScript](https://github.com/aws/aws-sdk-js)

## Finding contributions to work on
Looking at the existing issues is a great way to find something to contribute on. As our projects, by default, use the default GitHub issue labels (enhancement/bug/duplicate/help wanted/invalid/question/wontfix), looking at any ['help wanted'](https://github.com/aws-amplify/amplify-ios/labels/help%20wanted) or ['good first'](https://github.com/aws-amplify/amplify-ios/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+issue%22) issues is a great place to start.


## Code of Conduct
This project has adopted the [Amazon Open Source Code of Conduct](https://aws.github.io/code-of-conduct).
For more information see the [Code of Conduct FAQ](https://aws.github.io/code-of-conduct-faq) or contact
opensource-codeofconduct@amazon.com with any additional questions or comments.


## Security issue notifications
If you discover a potential security issue in this project we ask that you notify AWS/Amazon Security via our [vulnerability reporting page](http://aws.amazon.com/security/vulnerability-reporting/). Please do **not** create a public github issue.


## Licensing

See the [LICENSE](https://github.com/aws-amplify/amplify-ios/blob/main/LICENSE) file for our project's licensing. We will ask you to confirm the licensing of your contribution.

We may ask you to sign a [Contributor License Agreement (CLA)](http://en.wikipedia.org/wiki/Contributor_License_Agreement) for larger changes.
