//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum PredictionsError {
    case accessDenied(ErrorDescription, RecoverySuggestion)
}

extension PredictionsError: AmplifyError {
    public var errorDescription: ErrorDescription {
        return ""
    }

    public var recoverySuggestion: RecoverySuggestion {
        return ""
    }
}
