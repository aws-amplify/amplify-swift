//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation

/// A failure reported by the keychain layer.
///
/// Deliberately narrow: it carries the raw `OSStatus` rather than interpreting it, so each consumer maps
/// it to its own error type. `AWSPluginsCore` maps it one-to-one onto `KeychainStoreError`; a client can
/// use `storageUnavailableReason` to tell a locked device apart from a misconfiguration.
package enum KeychainAccessError: Equatable {

    /// No item is stored under the requested key.
    case itemNotFound

    /// A Security framework call failed with this status.
    case securityError(OSStatus)

    /// The call succeeded but returned something other than what was asked for.
    case unknown(ErrorDescription, Error? = nil)

    package static func == (lhs: KeychainAccessError, rhs: KeychainAccessError) -> Bool {
        switch (lhs, rhs) {
        case (.itemNotFound, .itemNotFound):
            return true
        case (.securityError(let lhsStatus), .securityError(let rhsStatus)):
            return lhsStatus == rhsStatus
        case (.unknown(let lhsDescription, _), .unknown(let rhsDescription, _)):
            return lhsDescription == rhsDescription
        default:
            return false
        }
    }
}

package extension KeychainAccessError {

    /// Why storage is unavailable, when this failure is one that means "unavailable" rather than
    /// "absent" or "broken". `nil` for `itemNotFound`, for unexpected results, and for any status the
    /// classifier does not recognise.
    var storageUnavailableReason: StorageUnavailableReason? {
        guard case .securityError(let status) = self else {
            return nil
        }
        return StorageUnavailableReason(keychainStatus: status)
    }
}

extension KeychainAccessError: AmplifyError {

    package init(
        errorDescription: ErrorDescription = "An unknown error occurred",
        recoverySuggestion: RecoverySuggestion = "(Ignored)",
        error: Error?
    ) {
        if let error = error as? Self {
            self = error
        } else {
            self = .unknown(errorDescription, error)
        }
    }

    package var errorDescription: ErrorDescription {
        switch self {
        case .itemNotFound:
            return "Unable to find the keychain item"
        case .securityError(let status):
            return KeychainStatus(status: status).description
        case .unknown(let errorDescription, _):
            return "Unexpected error occurred with message: \(errorDescription)"
        }
    }

    package var recoverySuggestion: RecoverySuggestion {
        switch self {
        case .itemNotFound:
            return ""
        case .securityError:
            if let reason = storageUnavailableReason {
                switch reason {
                case .locked:
                    return "The device is locked. Retry once it has been unlocked."
                case .interrupted:
                    return "A transient keychain failure occurred. Retry with backoff."
                case .denied:
                    return "Check the app's keychain entitlements and access group configuration."
                }
            }
            return defaultRecoverySuggestion
        case .unknown:
            return defaultRecoverySuggestion
        }
    }

    package var underlyingError: Error? {
        switch self {
        case .unknown(_, let error):
            return error
        case .itemNotFound, .securityError:
            return nil
        }
    }
}
