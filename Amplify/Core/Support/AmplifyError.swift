//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Convenience typealias to disambiguate positional parameters of AmplifyErrors
public typealias ErrorDescription = String

/// Convenience typealias to disambiguate positional parameters of AmplifyErrors
public typealias RecoverySuggestion = String

public typealias ErrorName = String
public typealias Field = String
public typealias Key = String
public typealias TargetIdentityId = String

/// Amplify's philosophy is to expose friendly error messages to the customer that assist with debugging.
/// Therefore, failable APIs are declared to return error results with Amplify errors, which require
/// recovery suggestions and error messages.
public protocol AmplifyError: Error, CustomDebugStringConvertible {
    /// A localized message describing what error occurred.
    var errorDescription: ErrorDescription { get }

    /// A localized message describing how one might recover from the failure.
    var recoverySuggestion: RecoverySuggestion { get }

    /// The underlying error that caused the error condition
    var underlyingError: Error? { get }

    /// AmplifyErrors must be able to be initialized from an underlying error. If an AmplifyError is created
    /// with this initializer, it must store the underlying error in the `underlyingError` property so it can be
    /// inspected later.
    ///
    /// Implementations of this method should handle the case where `error` is already an instance of `Self`, and simply
    /// return `self` as the incoming `error`.
    init(errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion, error: Error)
}

public extension AmplifyError {
    var debugDescription: String {
        let errorType = type(of: self)

        var components = ["\(errorType): \(errorDescription)"]

        if !recoverySuggestion.isEmpty {
            components.append("Recovery suggestion: \(recoverySuggestion)")
        }

        if let underlyingError = underlyingError {
            if let underlyingAmplifyError = underlyingError as? AmplifyError {
                components.append("Caused by:\n\(underlyingAmplifyError.debugDescription)")
            } else {
                components.append("Caused by:\n\(underlyingError)")
            }
        }

        return components.joined(separator: "\n")
    }
}
