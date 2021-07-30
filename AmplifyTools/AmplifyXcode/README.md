## AmplifyXcode
<img src="https://s3.amazonaws.com/aws-mobile-hub-images/aws-amplify-logo.png" alt="AWS Amplify" width="550" >

AmplifyXcode is a command line tool distributed as part of the Amplify CLI. It aims to provide a seamless integration between Xcode and Amplify CLI during development of Amplify-based applications.
AmplifyXcode exposes three commands that allow to update an Xcode project files with the generated Amplify Swift models and configuration files.
It's designed to be extensible and its core, `AmplifyXcodeCore`, is fully decoupled from the command line interface.
## Platform Support
AmplifyXcode is available on MacOS 10.13 and above.
## License
This program is licensed under the Apache 2.0 License.

## Commands
`amplify-xcode import-config --path project-path`
Imports Amplify project files into the Xcode project located at the provided *project-path*.

`amplify-xcode import-models --path project-path`
Imports Amplify generated Swift models into the Xcode project located at the provided *project-path*.

`amplify-xcode generate-schema --output-path output`
Generates a JSON description of its commands that can be used to programmatically call amplify-xcode from a different environment.
The Amplify CLI reads the output of this command to generate a [NodeJS bridging module](https://github.com/aws-amplify/amplify-cli/blob/master/packages/amplify-frontend-ios/lib/amplify-xcode.js) to safely invoke the above commands as described in the **CLI Integration** section.

## CLI integration
When running `amplify init --quickstart --frontend ios` as described in the [Getting Started guide](https://docs.amplify.aws/start/getting-started/setup/q/integration/ios#add-amplify-to-your-application), the relevant files are automatically added to the Xcode project in a `AmplifyConfig` group.
When running `amplify codegen models`, the `*.swift` files generated under `amplify/generated/models/` are auto-added to the Xcode project in the group called `AmplifyModels`.

## Reporting Bugs/Feature Requests
We welcome you to use the GitHub issue tracker to report bugs or suggest features.
When filing an issue, please check [existing open](https://github.com/aws-amplify/amplify-ios/issues?q=is%3Aissue+label%3Abug+label%3A%22dev+tools%22++is%3Aopen), or [recently closed](https://github.com/aws-amplify/amplify-ios/issues?q=is%3Aissue+label%3Abug+label%3A%22dev+tools%22++is%3Aclosed), issues to make sure somebody else hasn't already reported the issue.
Please try to include as much information as you can, details like these are incredibly useful:

- Expected behavior and observed behavior
- A reproducible test case or series of steps
- Anything custom about your environment or Xcode project/workspace

## Open Source Contributions
Pull requests guidelines https://github.com/aws-amplify/amplify-ios/blob/main/CONTRIBUTING.md#pull-requests

### Setup
AmplifyXcode requires Xcode 11.4 or higher to build.

After you've forked and cloned Amplify repository, navigate to the **AmplifyXcode** folder and open the Swift package:
```
cd AmplifyTools/AmplifyXcode
xed .
```
Xcode will take care of downloading the necessary dependencies.

### Testing
AmplifyXcode has a comprehensive suite of unit tests that you can easily run via Xcode UI or by running
`swift test` in your terminal from within the AmplifyXcode root folder.

While debugging within Xcode, you might also find useful to invoke the executable with specific commands and/or options.
In order to do so you can create a copy of the *amplify-xcode* scheme in the Xcode scheme editor (**Product > Scheme > edit Scheme**) and change the arguments passed to the executable on launch
in the *Arguments* tab.

Running `swift build -c release --disable-sandbox` will generate a release executable located at `.build/release/amplify-xcode`.

### Dependencies
- [Apple Swift Argument Parser](https://github.com/apple/swift-argument-parser)
- [XcodeProj](https://github.com/tuist/xcodeproj)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- [PathKit](https://github.com/kylef/PathKit)