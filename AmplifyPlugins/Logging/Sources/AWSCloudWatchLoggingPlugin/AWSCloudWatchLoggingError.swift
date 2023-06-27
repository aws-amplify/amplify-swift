//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Represents domain-specific errors within the AWSCloudWatchLogPlugin subsystem.
/// 
struct AWSCloudWatchLoggingError: AmplifyError {

    var errorDescription: String
    
    var recoverySuggestion: String
    
    var underlyingError: Error?
    
    init(errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion, error: Error) {
        self.errorDescription = errorDescription
        self.recoverySuggestion = recoverySuggestion
        self.underlyingError = error
    }
    
    init(errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion) {
        self.errorDescription = errorDescription
        self.recoverySuggestion = recoverySuggestion
        self.underlyingError = nil
    }
}
