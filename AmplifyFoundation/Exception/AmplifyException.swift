//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

public typealias FoundationErrorDescription = String
public typealias FoundationRecoverySuggestion = String

public struct FoundationAmplifyException: Error {
    var errorDescription: FoundationErrorDescription
    var recoverySuggestion: FoundationRecoverySuggestion
    var underlyingError: Error?
    
    init(
        errorDescription: FoundationErrorDescription,
        recoverySuggestion: FoundationRecoverySuggestion,
        error: Error
    ) {
        self.errorDescription = errorDescription
        self.recoverySuggestion = recoverySuggestion
        self.underlyingError = error
    }
}
