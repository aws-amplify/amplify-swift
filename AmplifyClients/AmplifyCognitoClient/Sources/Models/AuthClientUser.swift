//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The signed-in user of a session.
///
/// The client's own counterpart of Amplify core's `AuthUser` protocol. The client does not depend
/// on Amplify core, so it owns this type and the plugin bridge maps it. It is a concrete value
/// rather than a protocol so that `AuthSessionState` can be `Equatable` and so that two sessions'
/// users can be compared or used as dictionary keys.
@_spi(AmplifyExperimental)
public struct AuthClientUser: Sendable, Equatable, Hashable {

    /// User name of the user.
    public let username: String

    /// Unique id of the user: the user pool `sub`.
    public let userId: String

    public init(username: String, userId: String) {
        self.username = username
        self.userId = userId
    }
}
