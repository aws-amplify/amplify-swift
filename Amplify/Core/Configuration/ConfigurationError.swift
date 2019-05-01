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
}

extension ConfigurationError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .amplifyAlreadyConfigured(let description, _):
            return description
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .amplifyAlreadyConfigured(_, let recoverySuggestion):
            return recoverySuggestion
        }
    }

}
