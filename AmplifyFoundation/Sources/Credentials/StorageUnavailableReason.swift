//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Why secure storage could not be read or written.
///
/// A storage failure is not the same thing as having no credentials. Conflating the
/// two makes an app show a sign-in screen to a user who is already signed in, and the
/// most common cause — a locked device during background launch — resolves on its own.
/// Carrying a reason lets a caller tell "wait and retry" apart from "this will never
/// work until someone fixes the configuration".
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum StorageUnavailableReason: Sendable, Equatable {

    /// The device is locked, so protected storage is unreadable. Transient: retry once
    /// the device is unlocked.
    case locked

    /// A transient I/O or keystore failure. Retry with backoff.
    case interrupted

    /// An entitlement or access-group misconfiguration. Retrying will not help; this
    /// needs a build or provisioning fix.
    case denied
}
