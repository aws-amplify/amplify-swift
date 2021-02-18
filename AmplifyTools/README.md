## ⚠️ Deprecation notice
The build phase script provided by the `Amplify/Tools` pod is no longer recommended. It's *currently deprecated* and it **will be completely removed in a future release**.
As of Amplify CLI release **4.40.0**, the functionality provided by the `amplify-tools.sh` is currently integrated with the Amplify CLI. iOS projects can leverage it without adding any extra dependencies or build phases. Here is a description on how this dependency was replaced with the Amplify CLI:
- When running `amplify init --quickstart --frontend ios` as described in the [Getting Started guide](https://docs.amplify.aws/start/getting-started/setup/q/integration/ios#add-amplify-to-your-application), the relevant files are automatically added to the Xcode project.
- When running `amplify codegen models`, the `*.swift` files generated under `amplify/generated/models/` are auto-added to the Xcode project in the group called `AmplifyModels`.
**Notes:**
- Xcode integration was added to the Amplify CLI on [version `4.40.0`](https://github.com/aws-amplify/amplify-cli/releases/tag/v4.40.0), so make sure you update your CLI to the latest version.
- The "***Run Amplify Tools***" custom build phase script can be safely removed from existing projects.

### Amplify Tools

The "Amplify Tools" aims to provide a seamless integration between Xcode and [Amplify CLI](https://github.com/aws-amplify/amplify-cli). It installs the CLI and executes Amplify-related commands to make sure the iOS project has everything in place so developer can start using it right away.

See the [iOS Getting Started](https://aws-amplify.github.io/docs/ios/start#step-1-configure-your-app) for more details.
