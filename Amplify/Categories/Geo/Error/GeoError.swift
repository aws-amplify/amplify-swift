//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

///// Geo Error
//public enum GeoError {
//    /// Configuration Error
//    case configuration(ErrorDescription, RecoverySuggestion, Error? = nil)
//    /// Unknown Error
//    case unknown(ErrorDescription, RecoverySuggestion, Error? = nil)
//}
//
//extension GeoError: AmplifyError {
//    /// Initializer
//    /// - Parameters:
//    ///   - errorDescription: Error Description
//    ///   - recoverySuggestion: Recovery Suggestion
//    ///   - error: Underlying Error
//    public init(
//        errorDescription: ErrorDescription = "An unknown error occurred",
//        recoverySuggestion: RecoverySuggestion = "See `underlyingError` for more details",
//        error: Error) {
//        if let error = error as? Self {
//            self = error
//        } else if error.isOperationCancelledError {
//            self = .unknown("Operation cancelled", "", error)
//        } else {
//            self = .unknown(errorDescription, recoverySuggestion, error)
//        }
//    }
//
//    /// Error Description
//    public var errorDescription: ErrorDescription {
//        switch self {
//        case .configuration(let errorDescription, _, _):
//            return errorDescription
//        case .unknown(let errorDescription, _, _):
//            return "Unexpected error occurred with message: \(errorDescription)"
//        }
//    }
//
//    /// Recovery Suggestion
//    public var recoverySuggestion: RecoverySuggestion {
//        switch self {
//        case .configuration(_, let recoverySuggestion, _):
//            return recoverySuggestion
//        case .unknown:
//            return AmplifyErrorMessages.shouldNotHappenReportBugToAWS()
//        }
//    }
//
//    /// Underlying Error
//    public var underlyingError: Error? {
//        switch self {
//        case .configuration(_, _, let error):
//            return error
//        case .unknown(_, _, let error):
//            return error
//        }
//    }
//}

public extension Geo {
    struct Error: AmplifyError {
        public let errorDescription: ErrorDescription
        public let recoverySuggestion: RecoverySuggestion
        public let underlyingError: Swift.Error?
        
        public init(errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion, error: Swift.Error) {
            if let error = error as? Self {
                self = error
            } else if error.isOperationCancelledError {
                self = .unknown("Operation cancelled", error)
            } else {
                self = .unknown(errorDescription, error)
            }
        }
    }
}

extension Geo.Error: Equatable {
    public static func == (lhs: Geo.Error, rhs: Geo.Error) -> Bool {
        lhs.errorDescription == rhs.errorDescription &&
        lhs.recoverySuggestion == rhs.recoverySuggestion
    }
}

public extension Geo.Error {
    init(errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion, error: Swift.Error? = nil) {
        self.errorDescription = errorDescription
        self.recoverySuggestion = recoverySuggestion
        self.underlyingError = error
    }
    
    static let noAvailableMaps = Geo.Error(
        errorDescription: "There are no available map styles",
        recoverySuggestion: "There are no available map styles"
    )
    
    static let accessDeniedException = Geo.Error(
        errorDescription: "AccessDeniedException [400]",
        recoverySuggestion: "You do not have sufficient access to perform this action."
    )
    
    static let incompleteSignature = Geo.Error(
        errorDescription: "IncompleteSignature [400]",
        recoverySuggestion: "The request signature does not conform to AWS standards."
    )
    
    static let internalFailure = Geo.Error(
        errorDescription: "InternalFailure [500]",
        recoverySuggestion: "The request processing has failed because of an unknown error, exception or failure."
    )
    
    static func unknown(_ description: String, _ error: Swift.Error) -> Geo.Error {
        .init(
            errorDescription: description,
            recoverySuggestion: "",
            error: error
        )
    }
}
