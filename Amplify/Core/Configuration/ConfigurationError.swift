//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Errors associated with configuring and inspecting Amplify Categories
public enum ConfigurationError {
    /// The client issued a subsequent call to `Amplify.configure` after the first had already succeeded
    case amplifyAlreadyConfigured(ErrorDescription, RecoverySuggestion)

    /// The specified `amplifyconfiguration.json` file was not present or unreadable. Inspect `RecoverySuggestion` for
    /// the underlying error.
    case invalidAmplifyConfigurationFile(ErrorDescription, RecoverySuggestion)

    /// Unable to decode `amplifyconfiguration.json` into a valid AmplifyConfiguration object
    case unableToDecode(ErrorDescription, RecoverySuggestion)
}

extension ConfigurationError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .amplifyAlreadyConfigured(let description, _):
            return description
        case .invalidAmplifyConfigurationFile(let description, _):
            return description
        case .unableToDecode(let description, _):
            return description
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .amplifyAlreadyConfigured(_, let recoverySuggestion):
            return recoverySuggestion
        case .invalidAmplifyConfigurationFile(_, let recoverySuggestion):
            return recoverySuggestion
        case .unableToDecode(_, let recoverySuggestion):
            return recoverySuggestion
        }
    }

}
