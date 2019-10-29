//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum AnalyticsError {
    case unknown(ErrorDescription)
}

extension AnalyticsError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .unknown(let errorDescription):
            return "Unexpected error occurred with message: \(errorDescription)"
        }
    }

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .unknown:
            return """
                This should never happen. There is a possibility that there is bug if this error persists.
                Please take a look at https://github.com/aws-amplify/amplify-ios/issues to see if there are any
                existing issues that match your scenario, and file an issue with the details of the bug if there isn't.
                """
        }
    }
}
