//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation

public typealias ErrorDescription = String
public typealias RecoverySuggestion = String

/// This is the high level exception in the Amplify framework. Client specific exceptions should extend this.
/// It includes user friendly message
public protocol AmplifyError: Error {
    /// A localized message describing what error occurred.
    var errorDescription: ErrorDescription { get }
    
    /// A localized message describing how one might recover from the failure.
    var recoverySuggestion: RecoverySuggestion { get }
    
    /// The underlying error that caused the error condition
    var underlyingError: Error? { get }
    
    init(
        errorDescription: ErrorDescription,
        recoverySuggestion: RecoverySuggestion,
        error: Error?
    )
}
