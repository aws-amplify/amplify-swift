//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public typealias Identifier = String

public enum ConnectionProviderError {
    /// Caused by connection error
    case connection(Error?)

    case responseError

    /// Caused by JSON parse error.
    case jsonParse(Identifier?, Error?)

    /// Caused when a limit exceeded error occurs.
    case limitExceeded(Identifier?)

    /// Caused when any other subscription related error occurs. The second optional value is the error payload in
    /// dictionary format.
    case subscription(Identifier, [String: Any]?)

    /// Unknown error
    case unknown(ErrorDescription, Error? = nil)
}

extension ConnectionProviderError: AmplifyError {
    public var errorDescription: ErrorDescription {
        switch self {
        case .connection:
            return "There was a websocket connection error"
        case .responseError:
            return "There was a service response error"
        case .jsonParse:
            return "There was a deserialization issue."
        case .limitExceeded:
            return "Limit exceeded for connection"
        case .subscription:
            return "There was an error creating on the subscription. Take a look at the underlying error"
        case .unknown:
            return "Unknown error occured"
        }
    }

    // TODO: Fix up error handling in ConnectionProvider logic

    public var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .connection:
            return ""
        case .responseError:
            return ""
        case .jsonParse:
            return ""
        case .limitExceeded:
            return ""
        case .subscription:
            return ""
        case .unknown:
            return ""
        }
    }

    public var underlyingError: Error? {
        switch self {
        case .connection(let error):
            return error
        case .responseError:
            return nil
        case .jsonParse(_, let error):
            return error
        case .limitExceeded:
            return nil
        case .subscription:
            return nil
        case .unknown(_, let error):
            return error
        }
    }
}
