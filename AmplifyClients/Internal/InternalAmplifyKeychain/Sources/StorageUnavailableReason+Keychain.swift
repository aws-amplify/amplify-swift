//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Foundation
import Security

package extension StorageUnavailableReason {

    /// Classifies a keychain `OSStatus` as a reason storage is unavailable, or `nil` if the status does
    /// not mean "unavailable".
    ///
    /// A pure function of the status. `nil` covers success, `errSecItemNotFound` (absent is an answer,
    /// not an outage) and every status not listed below; callers treat those as ordinary failures.
    ///
    /// | Status | Reason |
    /// |---|---|
    /// | `errSecInteractionNotAllowed` | `.locked` — the device is locked, resolves on unlock |
    /// | `errSecMissingEntitlement`, `errSecAuthFailed`, `errSecNoAccessForItem` | `.denied` — a build or provisioning fix is needed |
    /// | `errSecIO`, `errSecNotAvailable` | `.interrupted` — transient, retry with backoff |
    ///
    /// Only the new client uses this. The Auth plugin's handling of keychain errors is deliberately left
    /// as it is.
    init?(keychainStatus status: OSStatus) {
        switch status {
        case errSecInteractionNotAllowed:
            self = .locked
        case errSecMissingEntitlement, errSecAuthFailed, errSecNoAccessForItem:
            self = .denied
        case errSecIO, errSecNotAvailable:
            self = .interrupted
        default:
            return nil
        }
    }
}
