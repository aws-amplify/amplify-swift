//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Error occured while using Prediction category
public enum PredictionsError {

    /// Access denied while executing the operation
    case accessDenied(ErrorDescription, RecoverySuggestion)
}

extension PredictionsError: AmplifyError {
    // TODO: Add description
    public var errorDescription: ErrorDescription {
        return ""
    }

    // TODO: Add recovery suggestion
    public var recoverySuggestion: RecoverySuggestion {
        return ""
    }
}
