# Amplify Configuration Tests

Amplify supports configuration from an in-memory `AmplifyConfiguration` object, from an
`amplifyconfiguration.json` file (Gen1, which deserializes into an `AmplifyConfiguration`),
or from an `amplify_outputs.json` file (Gen2, which deserializes into `AmplifyOutputsData`).

Test fixtures live alongside the tests rather than in this directory — see
`AmplifyConfigurationInitializationTests.swift` and `AmplifyOutputsInitializationTests.swift`.
As we add new categories, extend the fixtures in those tests to ensure compatibility.
