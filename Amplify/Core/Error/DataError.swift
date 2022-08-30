//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Errors associated with data-related operations on Amplify. Commonly
/// used by the API and DataStore categories.
enum DataError: Error {

    /// Indicates some data marked as required was unavailable.
    case dataUnavailable

    /// Indicates that expected data could not be loaded due to the
    /// lack of integrity.
    case dataIntegrity(underlyingError: Error? = nil)

    /// Indicates an unexpected scenario happened and the specific
    /// error could not be resolved.
    case unknown(ErrorDescription, RecoverySuggestion, Error)
}

extension DataError: AmplifyError {

    var errorDescription: ErrorDescription {
        switch self {
        case .dataUnavailable:
            return "A property marked as required was unavailable."
        case .dataIntegrity:
            return "A property was expected to exist but could not be found."
        case let .unknown(errorDescription, _, _):
            return errorDescription
        }
    }

    var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .dataUnavailable:
            return """
                   When a new instance of a model is created, the lazy references are only available
                   if the data was passed to the initializer.
                   """
        case .dataIntegrity:
            return """
                   This error typically occurs when there's a problem with the data integrity, such
                   as foreign keys with reference to unexisting records. Check your underlying
                   data storage for such inconsistencies.
                   """
        case let .unknown(_, recoverySuggestion, _):
            return recoverySuggestion
        }
    }

    var underlyingError: Error? {
        switch self {
        case let .dataIntegrity(underlyingError):
            return underlyingError
        case let .unknown(_, _, underlyingError):
            return underlyingError
        default:
            return nil
        }
    }

    public init(
        errorDescription: ErrorDescription = "An unknown error occurred",
        recoverySuggestion: RecoverySuggestion = "N/A",
        error: Error
    ) {
        if let error = error as? Self {
            self = error
        } else {
            self = .unknown(errorDescription, recoverySuggestion, error)
        }
    }

}
