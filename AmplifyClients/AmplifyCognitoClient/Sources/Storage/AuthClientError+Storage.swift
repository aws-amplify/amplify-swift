//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation
import InternalAmplifyKeychain

extension AuthClientError {

    /// Converts a keychain failure into `storageUnavailable`. Never into "absent": callers only reach
    /// this for a failure, and an item that is genuinely not there is handled before it.
    ///
    /// The reason comes from the keychain classifier. A status the classifier does not recognise, and a
    /// result of the wrong shape, are reported as `.interrupted`: storage still could not be read, and
    /// retrying with backoff is the cautious answer — reading it as "no session" would show sign-in to a
    /// user who is signed in.
    static func storageUnavailable(from error: Error, operation: String) -> AuthClientError {
        if let error = error as? AuthClientError {
            return error
        }
        let keychainError = error as? KeychainAccessError
        let reason = keychainError?.storageUnavailableReason ?? .interrupted
        let detail = (keychainError?.errorDescription).map { ": \($0)" } ?? ""
        return .storageUnavailable(
            reason,
            "Secure storage could not \(operation)\(detail).",
            recoverySuggestion(for: reason),
            error
        )
    }

    private static func recoverySuggestion(for reason: StorageUnavailableReason) -> RecoverySuggestion {
        switch reason {
        case .locked:
            return "The device is locked. Retry once it has been unlocked; do not treat this as signed out."
        case .interrupted:
            return "A transient keychain failure occurred. Retry with backoff; do not treat this as signed out."
        case .denied:
            return "Check the app's keychain entitlements and access group configuration. Retrying will not help."
        }
    }
}
