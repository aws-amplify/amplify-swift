//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

typealias PredictionsValidationErrorString = (field: Field,
    errorDescription: ErrorDescription,
    recoverySuggestion: RecoverySuggestion)
typealias PredictionsServiceErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)

struct PredictionsErrorConstants {
    static let accessDenied: PredictionsServiceErrorString = (
           "Access denied!",
           "")
}
