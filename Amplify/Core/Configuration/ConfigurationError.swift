//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Errors associated with configuring and inspecting Amplify Categories
public enum ConfigurationError {
    /// The client issued a subsequent call to `Amplify.configure` after the first had already succeeded
    case amplifyAlreadyConfigured(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// The specified `amplifyconfiguration.json` file was not present or unreadable
    case invalidAmplifyConfigurationFile(ErrorDescription, RecoverySuggestion, Error? = nil)

    /// Unable to decode `amplifyconfiguration.json` into a valid AmplifyConfiguration object
    case unableToDecode(ErrorDescription, RecoverySuggestion, Error? = nil)
}

extension ConfigurationError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .amplifyAlreadyConfigured(let description, _, _),
             .invalidAmplifyConfigurationFile(let description, _, _),
             .unableToDecode(let description, _, _):
            return description
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .amplifyAlreadyConfigured(_, let recoverySuggestion, _),
             .invalidAmplifyConfigurationFile(_, let recoverySuggestion, _),
             .unableToDecode(_, let recoverySuggestion, _):
            return recoverySuggestion
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .amplifyAlreadyConfigured(_, _, let underlyingError),
             .invalidAmplifyConfigurationFile(_, _, let underlyingError),
             .unableToDecode(_, _, let underlyingError):
            return underlyingError
        }
    }
}
