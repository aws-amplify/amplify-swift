//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

public typealias ErrorDescription = String
public typealias RecoverySuggestion = String

public struct AmplifyException: Error {
    var errorDescription: ErrorDescription
    var recoverySuggestion: RecoverySuggestion
    var underlyingError: Error?
    
    init(
        errorDescription: ErrorDescription,
        recoverySuggestion: RecoverySuggestion,
        error: Error
    ) {
        self.errorDescription = errorDescription
        self.recoverySuggestion = recoverySuggestion
        self.underlyingError = error
    }
}
