//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public enum AWSAPICategoryPluginError {
    case configuration(ErrorDescription, RecoverySuggestion)
}

extension AWSAPICategoryPluginError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .configuration(let errorDescription, _):
            return errorDescription
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .configuration(_, let recoverySuggestion):
            return recoverySuggestion
        }
    }
}
