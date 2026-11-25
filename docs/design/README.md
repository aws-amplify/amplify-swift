# AmplifyCognitoClient design documents

| Document | What it is |
|---|---|
| [`AGREED-DESIGN-AmplifyCognitoClient.md`](AGREED-DESIGN-AmplifyCognitoClient.md) | The design: a standalone Cognito auth client (`AmplifyCognitoClient`), its session and storage model, and its API surface. Implemented as a beta, behind `@_spi(AmplifyExperimental)`. |
| [`auth-client-DECISIONS.md`](auth-client-DECISIONS.md) | The decisions taken in review of the design and while building it, with the options weighed and the evidence behind each. |
| [`RELEASE-NOTES-PENDING.md`](RELEASE-NOTES-PENDING.md) | Customer-visible changes, in the plugin, in the released Kinesis and Firehose clients and in the new client, that the next releases' notes must include. |
| [`RELEASE-NOTES-2.63.1.md`](RELEASE-NOTES-2.63.1.md) | The rows 2.63.1 shipped: what each of its changes to the plugin and the new client means for an app. |
| [`issues/`](issues/README.md) | Issues found while building the client, left for later discussion, each with its status. |

Using the client: [the beta guide](../../AmplifyClients/AmplifyCognitoClient/README.md). Running its integration tests: [the integration test README](../../AmplifyClients/AmplifyCognitoClient/Tests/IntegrationTests/README.md).
