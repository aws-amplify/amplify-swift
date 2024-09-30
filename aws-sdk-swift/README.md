# <img alt="aws_logo.png" src="https://avatars.githubusercontent.com/u/3299148?s=200&v=4" width="28"> AWS SDK for Swift

[![License][apache-badge]][apache-url]

[apache-badge]: https://img.shields.io/badge/License-Apache%202.0-blue.svg
[apache-url]: LICENSE

## Getting Started

- [SDK Product Page](https://aws.amazon.com/sdk-for-swift/)
- [Developer Guide](https://docs.aws.amazon.com/sdk-for-swift/latest/developer-guide/home.html)
- [API Reference](https://sdk.amazonaws.com/swift/api/awssdkforswift/latest/documentation/awssdkforswift)
- [Code Examples Repo](https://github.com/awsdocs/aws-doc-sdk-examples/tree/main/swift)

To get started using the SDK, follow the setup instructions at [Set up the AWS SDK for Swift](https://docs.aws.amazon.com/sdk-for-swift/latest/developer-guide/setting-up.html), then check out our step-by-step tutorial at [Get started with the AWS SDK for Swift](https://docs.aws.amazon.com/sdk-for-swift/latest/developer-guide/getting-started.html).

## Feedback

If you'd like to provide feedback, report a bug, request a feature, or would like to bring
attention to an issue in general, please do so by submitting a GitHub issue to the repo [here](https://github.com/awslabs/aws-sdk-swift/issues/new/choose).

This is the preferred mechanism for user feedback as it allows anyone with similar issue or suggestion to engage in conversation as well.

## Contributing

If you are interested in contributing to AWS SDK for Swift, see [CONTRIBUTING](CONTRIBUTING.md) for more information.

## Development

### Runtime Modules (under `Sources/Core/`)

* `AWSClientRuntime` - concrete types, protocols, enums, etc. that provide most AWS specific runtime functionalities for the SDK. 
                       Has several other runtime modules as its dependencies.
* `AWSSDKChecksums` - implementation for handling checksum in AWS requests
* `AWSSDKCommon` - concrete types used by other runtime modules
* `AWSSDKEventStreamsAuth` - concrete types for signing AWS event stream message
* `AWSSDKHTTPAuth` - concrete types for AWS SigV4 signer, and types related to auth flow
* `AWSSDKIdentity` - concrete types for AWS credentials and identity resolvers

> 📖 For more information on runtime modules, see [the AWS Runtime Module Documentation in API reference](https://sdk.amazonaws.com/swift/api/awssdkforswift/latest/documentation/awssdkforswift#AWS-Runtime-Module-Documentation)

## License

This library is licensed under the Apache 2.0 License.

## Security

Please refer to our [security policy](https://github.com/awslabs/aws-sdk-swift/security/policy).